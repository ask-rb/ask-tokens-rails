# frozen_string_literal: true

require "ask/tokens/stores/store"

module Ask
  module Tokens
    module Rails
      # ActiveRecord-backed wallet store. Each mutation (grant/deduct) does
      # its own read-write under a single DB call. The wallet row is created
      # lazily on first access. No outer transaction wrapping — each AR
      # create/update handles its own atomicity.
      class ActiveRecordStore < Ask::Tokens::Stores::Store
        def balance(owner)
          resolve_wallet(owner)&.balance || 0
        end

        def entries(owner, kind: nil, since: nil)
          row = resolve_wallet(owner)
          return [] unless row

          scope = row.token_transactions.order(:created_at)
          scope = scope.where(entry_type: kind.to_s) if kind
          scope = scope.where("created_at >= ?", since) if since
          scope.map { |t| to_entry(t) }
        end

        # No-op for in-process locking. For production with PostgreSQL,
        # this could use row-level locks. SQLite uses file-level locks
        # which are handled by the OS.
        def with_lock(owner)
          yield
        end

        def append(owner, entry)
          row = find_or_create_wallet!(owner)
          meta = entry.metadata || {}
          txn = Ask::Tokens::TokenTransaction.create!(
            token_wallet_id: row.id,
            entry_type: entry.kind.to_s,
            amount: entry.amount,
            reason: entry.reason,
            metadata: meta,
            expires_at: entry.expires_at,
            balance: entry.balance,
            created_at: entry.created_at,
            **extract_columns_from_metadata(meta)
          )
          entry.with(id: txn.id)
        end

        def write_balance(owner, amount)
          row = find_or_create_wallet!(owner)
          row.update_column(:balance, amount)
        end

        private

        def find_or_create_wallet!(owner)
          owner_type, owner_id = resolve_owner(owner)
          Ask::Tokens::TokenWallet.find_by(owner_type: owner_type, owner_id: owner_id) ||
            begin
              Ask::Tokens::TokenWallet.create!(owner_type: owner_type, owner_id: owner_id, balance: 0)
            rescue ActiveRecord::RecordNotUnique
              Ask::Tokens::TokenWallet.find_by!(owner_type: owner_type, owner_id: owner_id)
            end
        end

        def resolve_wallet(owner)
          owner_type, owner_id = resolve_owner(owner)
          Ask::Tokens::TokenWallet.find_by(owner_type: owner_type, owner_id: owner_id)
        end

        def resolve_owner(owner)
          if owner.respond_to?(:id) && owner.respond_to?(:class) && owner.class.respond_to?(:polymorphic_name)
            [owner.class.polymorphic_name, owner.id]
          else
            [owner.class.name, owner.respond_to?(:id) ? owner.id : owner.to_s]
          end
        end

        def to_entry(txn)
          Ask::Tokens::LedgerEntry.new(
            id: txn.id,
            kind: txn.entry_type.to_sym,
            amount: txn.amount,
            reason: txn.reason,
            expires_at: txn.expires_at,
            metadata: txn.metadata,
            balance: txn.balance,
            created_at: txn.created_at
          )
        end

        # Extract well-known metadata keys into their matching model columns.
        # Only writes keys that exist in metadata, so grants/debits without
        # LLM context are unaffected. Symbol and string keys are both handled.
        COLUMN_KEYS = %i[model_id provider input_tokens output_tokens cached_tokens llm_cost_usd multiplier].freeze

        def extract_columns_from_metadata(meta)
          COLUMN_KEYS.each_with_object({}) do |key, hash|
            value = meta[key] || meta[key.to_s]
            hash[key] = value if value
          end
        end
      end
    end
  end
end
