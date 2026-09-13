# frozen_string_literal: true

module Ask
  module Tokens
    module Rails
      # Table names are prefixed with the gem's name by default, so they can
      # never collide with an app's own ledger — no configuration needed.
      # Override only to adopt existing tables:
      #
      #   Ask::Tokens::Rails.configure do |config|
      #     config.wallets_table = "token_wallets"
      #     config.transactions_table = "token_transactions"
      #   end
      class Configuration
        attr_accessor :wallets_table, :transactions_table

        def initialize
          @wallets_table = "ask_tokens_wallets"
          @transactions_table = "ask_tokens_transactions"
        end
      end

      class << self
        def config
          @config ||= Configuration.new
        end

        def configure
          yield config
        end

        def reset_config!
          @config = Configuration.new
        end
      end
    end
  end
end
