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

          Ask::Tokens.configure do |c|
            c.store = Ask::Tokens::Rails::ActiveRecordStore.new
          end
        end
      end
    end
  end
end
