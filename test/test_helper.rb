if ENV["COVERAGE"]
  require "simplecov"
  SimpleCov.start do
    add_filter "/test/"
    add_filter "/vendor/"
    track_files "lib/**/*.rb"
  end
end

$LOAD_PATH.unshift File.expand_path("../../lib", __dir__)

require "active_record"
require "ask-tokens"
require "ask/tokens/rails/models/token_wallet"
require "ask/tokens/rails/models/token_transaction"
require "ask/tokens/rails/stores/active_record_store"
require "ask/tokens/rails/concerns/has_token_wallet"
require "ask/tokens/rails/jobs/sweep_expired_tokens_job"

ActiveRecord::Base.establish_connection(adapter: "sqlite3", database: ":memory:")
ActiveRecord::Base.logger = nil unless ENV["LOG"]
ActiveRecord::Base.extend(Ask::Tokens::Rails::TokenWalletOwner)

ActiveRecord::Schema.define do
  suppress_messages do
    create_table :ask_tokens_wallets do |t|
      t.string :owner_type, null: false
      t.bigint :owner_id, null: false
      t.bigint :balance, null: false, default: 0
      t.timestamps
    end
    add_index :ask_tokens_wallets, %i[owner_type owner_id], unique: true

    create_table :ask_tokens_transactions do |t|
      t.references :token_wallet, null: false, foreign_key: {to_table: :ask_tokens_wallets}
      t.string :entry_type, null: false
      t.bigint :amount, null: false
      t.string :reason, null: false
      t.json :metadata, null: false, default: {}
      t.bigint :balance, null: false
      t.datetime :expires_at
      t.string :model_id
      t.string :provider
      t.bigint :input_tokens
      t.bigint :output_tokens
      t.bigint :cached_tokens
      t.decimal :llm_cost_usd, precision: 12, scale: 8
      t.decimal :multiplier, precision: 6, scale: 4, default: 1.0, null: false
      t.datetime :created_at, null: false
    end
    add_index :ask_tokens_transactions, %i[token_wallet_id created_at]

    create_table :test_users, force: true do |t|
      t.string :name
    end
  end
end

# Stub model to test the concern without a full Rails app
class TestUser < ActiveRecord::Base
  include Ask::Tokens::Rails::HasTokenWallet
end

# Stub model to test the `has_token_wallet` macro
class MacroUser < ActiveRecord::Base
  self.table_name = "test_users"
  has_token_wallet
end

require "minitest/autorun"
