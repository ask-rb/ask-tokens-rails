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
require "ask-token-usage"
require "ask/token_usage/rails/models/token_wallet"
require "ask/token_usage/rails/models/token_transaction"
require "ask/token_usage/rails/stores/active_record_store"
require "ask/token_usage/rails/concerns/has_token_wallet"

ActiveRecord::Base.establish_connection(adapter: "sqlite3", database: ":memory:")
ActiveRecord::Base.logger = nil unless ENV["LOG"]

ActiveRecord::Schema.define do
  suppress_messages do
    create_table :token_wallets do |t|
      t.string :owner_type, null: false
      t.bigint :owner_id, null: false
      t.bigint :balance, null: false, default: 0
      t.timestamps
    end
    add_index :token_wallets, %i[owner_type owner_id], unique: true

    create_table :token_transactions do |t|
      t.references :token_wallet, null: false, foreign_key: true
      t.string :entry_type, null: false
      t.bigint :amount, null: false
      t.string :reason, null: false
      t.json :metadata, null: false, default: {}
      t.bigint :balance, null: false
      t.datetime :expires_at
      t.datetime :created_at, null: false
    end
    add_index :token_transactions, %i[token_wallet_id created_at]

    create_table :test_users, force: true do |t|
      t.string :name
    end
  end
end

# Stub model to test the concern without a full Rails app
class TestUser < ActiveRecord::Base
  include Ask::TokenUsage::Rails::HasTokenWallet
end

require "minitest/autorun"
