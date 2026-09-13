# frozen_string_literal: true

class CreateAskTokensTables < ActiveRecord::Migration[7.0]
  def change
    create_table :<%= Ask::Tokens::Rails.config.wallets_table %> do |t|
      t.references :owner, polymorphic: true, null: false
      t.bigint :balance, null: false, default: 0
      t.timestamps
    end
    add_index :<%= Ask::Tokens::Rails.config.wallets_table %>, %i[owner_type owner_id], unique: true,
      name: "idx_<%= Ask::Tokens::Rails.config.wallets_table %>_owner"

    create_table :<%= Ask::Tokens::Rails.config.transactions_table %> do |t|
      t.references :token_wallet, null: false, foreign_key: {to_table: Ask::Tokens::Rails.config.wallets_table}
      t.string :entry_type, null: false
      t.bigint :amount, null: false
      t.string :reason, null: false
      t.jsonb :metadata, null: false, default: {}
      t.bigint :balance, null: false
      t.datetime :expires_at
      t.datetime :created_at, null: false
    end
    add_index :<%= Ask::Tokens::Rails.config.transactions_table %>, %i[token_wallet_id created_at]
    add_index :<%= Ask::Tokens::Rails.config.transactions_table %>, :entry_type
  end
end
