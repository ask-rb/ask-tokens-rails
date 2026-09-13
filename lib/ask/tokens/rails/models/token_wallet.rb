# frozen_string_literal: true

require "active_record"
require_relative "../configuration"

module Ask
  module Tokens
    # Polymorphic wallet record. One per owner. Holds the cached balance.
    class TokenWallet < ::ActiveRecord::Base
      def self.table_name
        Ask::Tokens::Rails.config.wallets_table
      end

      has_many :token_transactions, class_name: "Ask::Tokens::TokenTransaction",
                                   foreign_key: :token_wallet_id,
                                   dependent: :destroy,
                                   inverse_of: :token_wallet

      belongs_to :owner, polymorphic: true, optional: true

      validates :balance, numericality: { only_integer: true }
    end
  end
end
