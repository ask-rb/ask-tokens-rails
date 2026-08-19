# frozen_string_literal: true

require "rails/railtie"

module Ask
  module TokenUsage
    module Rails
      class Railtie < ::Rails::Railtie
        initializer "ask_token_usage.active_record_store" do
          require "ask/token_usage/rails/models/token_wallet"
          require "ask/token_usage/rails/models/token_transaction"
          require "ask/token_usage/rails/stores/active_record_store"
          require "ask/token_usage/rails/concerns/has_token_wallet"

          Ask::TokenUsage.configure do |c|
            c.store = Ask::TokenUsage::Rails::ActiveRecordStore.new
          end
        end
      end
    end
  end
end
