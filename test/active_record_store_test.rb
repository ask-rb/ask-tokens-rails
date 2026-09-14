require_relative "test_helper"

class ActiveRecordStoreTest < Minitest::Test
  def setup
    Ask::Tokens.reset!
    @store = Ask::Tokens::Rails::ActiveRecordStore.new
    Ask::Tokens.configure do |c|
      c.store = @store
      c.time = -> { Time.now }
    end
    @alice = TestUser.create!(name: "Alice")
    @bob   = TestUser.create!(name: "Bob")
  end

  def wallet(owner = @alice)
    Ask::Tokens.wallet_for(owner)
  end

  def test_balance_starts_at_zero
    assert_equal 0, wallet.balance
  end

  def test_grant_and_read_balance
    wallet.grant!(1000, reason: :signup)
    assert_equal 1000, wallet.balance
    assert_equal 1000, Ask::Tokens::TokenWallet.last.balance
  end

  def test_deduct_and_read_balance
    wallet.grant!(500, reason: :start)
    wallet.deduct!(200, reason: :render)
    assert_equal 300, wallet.balance
  end

  def test_ledger_entries_persist
    wallet.grant!(100, reason: :a)
    wallet.deduct!(30, reason: :b)
    entries = @store.entries(@alice)
    assert_equal 2, entries.length
    assert_equal :grant, entries.first.kind
    assert_equal :debit, entries.last.kind
  end

  def test_entries_filter_by_kind
    wallet.grant!(100, reason: :a)
    wallet.deduct!(10, reason: :b)
    assert_equal 1, @store.entries(@alice, kind: :grant).length
    assert_equal 1, @store.entries(@alice, kind: :debit).length
  end

  def test_separate_owners
    wallet(@alice).grant!(500, reason: :x)
    wallet(@bob).grant!(900, reason: :y)
    assert_equal 500, wallet(@alice).balance
    assert_equal 900, wallet(@bob).balance
  end

  def test_token_wallet_row_created
    wallet.grant!(100, reason: :init)
    row = Ask::Tokens::TokenWallet.last
    assert_equal 100, row.balance
    assert_equal "TestUser", row.owner_type
  end

  def test_token_transaction_row_created
    wallet.grant!(100, reason: :init)
    txn = Ask::Tokens::TokenTransaction.last
    assert_equal "grant", txn.entry_type
    assert_equal 100, txn.amount
    assert_equal "init", txn.reason
    assert_equal 100, txn.balance
  end

  def test_metadata_stored
    wallet.grant!(100, reason: :promo, metadata: { campaign: "beta" })
    txn = Ask::Tokens::TokenTransaction.last
    assert_equal({ "campaign" => "beta" }, txn.metadata)
  end

  def test_billing_detail_lifted_into_columns
    wallet.grant!(100, reason: :top_up)
    wallet.deduct!(25, reason: :llm_call, metadata: {
      model_id: "deepseek/deepseek-v4.1-flash",
      provider: "commandcode",
      input_tokens: 1_000,
      output_tokens: 250,
      cached_tokens: 400,
      llm_cost_usd: 0.00035,
      multiplier: 2.0
    })

    txn = Ask::Tokens::TokenTransaction.last
    assert_equal "deepseek/deepseek-v4.1-flash", txn.model_id
    assert_equal "commandcode", txn.provider
    assert_equal 1_000, txn.input_tokens
    assert_equal 250, txn.output_tokens
    assert_equal 400, txn.cached_tokens
    assert_in_delta 0.00035, txn.llm_cost_usd, 1e-9
    assert_in_delta 2.0, txn.multiplier, 1e-9
    # The full detail also stays queryable in metadata.
    assert_equal 1_000, txn.metadata["input_tokens"]
  end

  def test_billing_columns_are_optional
    wallet.grant!(100, reason: :signup)
    txn = Ask::Tokens::TokenTransaction.last
    assert_nil txn.model_id
    assert_equal 1.0, txn.multiplier
  end

  def test_insufficient_tokens_raises
    wallet.grant!(10, reason: :tiny)
    assert_raises(Ask::Tokens::InsufficientTokens) do
      wallet.deduct!(50, reason: :big)
    end
    assert_equal 10, wallet.balance
  end

  def test_adjust_balance_to_persists
    wallet.grant!(200, reason: :start)
    wallet.adjust_balance_to!(500, reason: :monthly_reset)
    assert_equal 500, wallet.balance
    row = Ask::Tokens::TokenWallet.find_by(owner: @alice)
    assert_equal 500, row.balance
  end

  def test_adjust_balance_to_records_transaction
    wallet.grant!(200, reason: :start)
    wallet.adjust_balance_to!(50, reason: :downgrade)
    txn = Ask::Tokens::TokenTransaction.where(token_wallet: Ask::Tokens::TokenWallet.find_by(owner: @alice)).last
    assert_equal "adjustment", txn.entry_type
    assert_equal(-150, txn.amount)
  end

  def test_with_lock_yields
    wallet.grant!(100, reason: :start)
    called = false
    @store.with_lock(@alice) { called = true }
    assert called
  end
end
