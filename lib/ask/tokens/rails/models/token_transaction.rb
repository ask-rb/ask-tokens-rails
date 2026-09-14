# frozen_string_literal: true

require "active_record"
require_relative "../configuration"

module Ask
  module Tokens
    # Append-only ledger row. Every grant, debit, adjustment, or expiry is
    # written here as an immutable record. Never updated or deleted.
    class TokenTransaction < ::ActiveRecord::Base
      def self.table_name
        Ask::Tokens::Rails.config.transactions_table
      end

      belongs_to :token_wallet, class_name: "Ask::Tokens::TokenWallet",
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
      # Everything that adds tokens to a wallet (grants and adjustments).
      scope :credits, -> { where(entry_type: %w[grant adjustment]) }
      scope :since, ->(time) { where("created_at >= ?", time) }
      scope :newest_first, -> { order(created_at: :desc) }

      def debit?
        entry_type == "debit"
      end

      def credit?
        %w[grant adjustment].include?(entry_type)
      end

      validate :immutable_after_creation, on: :update

      private

      def immutable_after_creation
        errors.add(:base, "Token transactions are append-only")
      end
    end
  end
end
