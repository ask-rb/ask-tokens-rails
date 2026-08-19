# frozen_string_literal: true

class CreateTokenWallets < ActiveRecord::Migration[7.0]
  def change
    create_table :token_wallets do |t|
      t.references :owner, polymorphic: true, null: false
      t.bigint :balance, null: false, default: 0
      t.timestamps
    end
    add_index :token_wallets, %i[owner_type owner_id], unique: true, name: "idx_token_wallets_owner"

    create_table :token_transactions do |t|
      t.references :token_wallet, null: false, foreign_key: true
      t.string :entry_type, null: false
      t.bigint :amount, null: false
      t.string :reason, null: false
      t.jsonb :metadata, null: false, default: {}
      t.bigint :balance, null: false
      t.datetime :expires_at
      t.datetime :created_at, null: false
    end
    add_index :token_transactions, %i[token_wallet_id created_at]
    add_index :token_transactions, :entry_type
  end
end
