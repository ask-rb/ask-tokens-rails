# frozen_string_literal: true

require "active_job"

module Ask
  module Tokens
    module Rails
      # Expire grant entries whose +expires_at+ has passed. Scheduled as a
      # recurring job (Solid Queue cron, Sidekiq Cron, etc.):
      #
      #   # config/recurring.yml (Solid Queue)
      #   ask_tokens_sweep:
      #     class: Ask::Tokens::Rails::SweepExpiredTokensJob
      #     schedule: every hour
      #
      # Grants are consumed first-to-expire-first: a debit draws from the
      # grant that will expire soonest (non-expiring grants last). Replaying
      # the wallet's ledger therefore tells us exactly how much of each
      # expired grant is left unspent — only that remainder is removed, so
      # expiry can never eat a later top-up. Recorded expiry rows count as
      # consumption of their source grant, which makes repeated runs
      # idempotent.
      #
      class SweepExpiredTokensJob < ActiveJob::Base
        queue_as :default

        def perform(now: Time.current)
          wallet_ids = Ask::Tokens::TokenTransaction
            .grants
            .where("expires_at IS NOT NULL AND expires_at <= ?", now)
            .distinct
            .pluck(:token_wallet_id)

          Ask::Tokens::TokenWallet.where(id: wallet_ids).find_each do |wallet|
            sweep_wallet(wallet, now: now)
          end
        end

        private

        def sweep_wallet(wallet, now:)
          wallet.with_lock do
            expired = expired_remainders(wallet, now: now)
            return if expired.empty?

            balance = wallet.balance
            expired.each do |grant, remaining|
              actual = [remaining, balance].min
              next if actual <= 0

              Ask::Tokens::TokenTransaction.create!(
                token_wallet_id: wallet.id,
                entry_type: "expiry",
                amount: -actual,
                reason: "token_expiry",
                balance: balance - actual,
                metadata: {
                  source_transaction_id: grant.id,
                  expired_amount: remaining,
                  actual_expired: actual
                },
                created_at: now
              )
              balance -= actual
            end

            wallet.update_column(:balance, balance)
          end
        end

        # [[grant, unspent_remainder], ...] for every grant whose window has
        # closed and that still has tokens left after replaying the wallet's
        # ledger.
        def expired_remainders(wallet, now:)
          rows = Ask::Tokens::TokenTransaction
            .where(token_wallet_id: wallet.id)
            .order(:created_at, :id)
            .to_a

          lots = rows
            .select { |row| row.entry_type == "grant" }
            .sort_by { |grant| [grant.expires_at ? 0 : 1, grant.expires_at || grant.created_at, grant.id] }
            .map { |grant| {grant: grant, remaining: grant.amount} }
          by_grant_id = lots.index_by { |lot| lot[:grant].id }

          rows.each do |row|
            case row.entry_type
            when "debit"
              consume(lots, -row.amount)
            when "expiry"
              lot = by_grant_id[row.metadata["source_transaction_id"].to_i]
              consume_lot(lot, -row.amount) if lot
            end
          end

          lots
            .select { |lot| lot[:remaining] > 0 && lot[:grant].expires_at && lot[:grant].expires_at <= now }
            .map { |lot| [lot[:grant], lot[:remaining]] }
        end

        def consume(lots, amount)
          lots.each do |lot|
            amount = consume_lot(lot, amount)
            break if amount <= 0
          end
        end

        def consume_lot(lot, amount)
          return amount if lot.nil? || amount <= 0

          taken = [lot[:remaining], amount].min
          lot[:remaining] -= taken
          amount - taken
        end
      end
    end
  end
end
