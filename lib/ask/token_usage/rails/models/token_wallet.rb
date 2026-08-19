# frozen_string_literal: true

require "active_record"

module Ask
  module TokenUsage
    # Polymorphic wallet record. One per owner. Holds the cached balance.
    class TokenWallet < ::ActiveRecord::Base
      self.table_name = "token_wallets"

      has_many :token_transactions, class_name: "Ask::TokenUsage::TokenTransaction",
                                   foreign_key: :token_wallet_id,
                                   dependent: :destroy,
                                   inverse_of: :token_wallet

      belongs_to :owner, polymorphic: true, optional: true

      validates :balance, numericality: { only_integer: true }
    end
  end
end
