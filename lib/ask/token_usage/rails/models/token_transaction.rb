# frozen_string_literal: true

require "active_record"

module Ask
  module TokenUsage
    # Append-only ledger row. Every grant, debit, adjustment, or expiry is
    # written here as an immutable record. Never updated or deleted.
    class TokenTransaction < ::ActiveRecord::Base
      self.table_name = "token_transactions"

      belongs_to :token_wallet, class_name: "Ask::TokenUsage::TokenWallet",
                                foreign_key: :token_wallet_id,
                                inverse_of: :token_transactions

      ENTRY_TYPES = %w[grant debit adjustment expiry].freeze
      validates :entry_type, presence: true, inclusion: { in: ENTRY_TYPES }
      validates :amount, presence: true, numericality: { only_integer: true }
      validates :reason, presence: true

      scope :grants, -> { where(entry_type: "grant") }
      scope :debits, -> { where(entry_type: "debit") }
      scope :adjustments, -> { where(entry_type: "adjustment") }
      scope :expiries, -> { where(entry_type: "expiry") }
      scope :since, ->(time) { where("created_at >= ?", time) }
      scope :newest_first, -> { order(created_at: :desc) }

      validate :immutable_after_creation, on: :update

      private

      def immutable_after_creation
        errors.add(:base, "Token transactions are append-only")
      end
    end
  end
end
