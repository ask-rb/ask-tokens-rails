# frozen_string_literal: true

require "rails/railtie"

module Ask
  module Tokens
    module Rails
      class Railtie < ::Rails::Railtie
        initializer "ask_tokens.active_record_store" do
          require "ask/tokens/rails/models/token_wallet"
          require "ask/tokens/rails/models/token_transaction"
          require "ask/tokens/rails/stores/active_record_store"
          require "ask/tokens/rails/concerns/has_token_wallet"
          require "ask/tokens/rails/jobs/sweep_expired_tokens_job"

          Ask::Tokens.configure do |c|
            c.store = Ask::Tokens::Rails::ActiveRecordStore.new
          end
        end

        initializer "ask_tokens.has_token_wallet_macro" do
          ActiveSupport.on_load(:active_record) do
            extend Ask::Tokens::Rails::TokenWalletOwner
          end
        end
      end
    end
  end
end
