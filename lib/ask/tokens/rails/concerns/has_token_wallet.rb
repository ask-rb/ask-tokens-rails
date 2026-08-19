# frozen_string_literal: true

require "active_support/concern"

module Ask
  module Tokens
    module Rails
      # Include this concern in any ActiveRecord model to give it a token
      # wallet backed by ask-tokens-rails.
      #
      #   class User < ApplicationRecord
      #     has_token_wallet
      #   end
      #
      # Adds:
      #   user.token_balance        # Integer
      #   user.token_wallet         # Ask::Tokens::TokenWallet (lazy-created)
      #   user.token_transactions   # AR scope for the ledger
      #   user.grant_tokens!(...)   # convenience
      #   user.spend_tokens!(...)   # convenience
      #   user.spend_tokens_on!(...)# convenience (activity name + block)
      #
      module HasTokenWallet
        extend ActiveSupport::Concern

        included do
          has_one :token_wallet, as: :owner,
                                 class_name: "Ask::Tokens::TokenWallet",
                                 dependent: :destroy,
                                 inverse_of: :owner

          has_many :token_transactions, through: :token_wallet
        end

        def ensure_token_wallet!
          # Force wallet row creation by probing balance through the AR store
          Ask::Tokens.wallet_for(self).balance
        end

        def token_balance
          Ask::Tokens.wallet_for(self).balance
        end

        # Build an Ask::Tokens::Wallet PORO backed by this model's
        # AR wallet — use for one-off operations outside the concern API.
        def ask_token_wallet
          Ask::Tokens.wallet_for(self)
        end

        # Grant +amount+ tokens.
        def grant_tokens!(amount, reason:, expires_at: nil, metadata: {})
          ask_token_wallet.grant!(amount, reason: reason, expires_at: expires_at, metadata: metadata)
        end

        # Deduct +amount+ tokens, raising InsufficientTokens on failure.
        def deduct_tokens!(amount, reason:, metadata: {})
          ask_token_wallet.deduct!(amount, reason: reason, metadata: metadata)
        end

        # Deduct +amount+ tokens; returns false instead of raising on
        # insufficient balance.
        def try_deduct_tokens!(amount, reason:, metadata: {})
          deduct_tokens!(amount, reason: reason, metadata: metadata)
        rescue Ask::Tokens::InsufficientTokens
          false
        end

        # Spend the estimated cost of +activity+ with +params+, charging
        # only when the block succeeds.
        def spend_tokens_on!(activity_name, params = {}, &block)
          ask_token_wallet.spend!(activity_name, params, &block)
        end

        # Spend an explicit +amount+ of tokens, charging only on block success.
        def spend_tokens!(amount, reason:, metadata: {}, &block)
          ask_token_wallet.deduct!(amount, reason: reason, metadata: metadata, &block)
        end

        def has_tokens_for?(amount)
          ask_token_wallet.has?(amount)
        end

        def tokens_since(time)
          ask_token_wallet.used_since(time)
        end
      end
    end
  end
end
