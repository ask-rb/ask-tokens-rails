require_relative "test_helper"

class HasTokenWalletTest < Minitest::Test
  def setup
    Ask::Tokens.reset!
    Ask::Tokens.configure { |c| c.store = Ask::Tokens::Rails::ActiveRecordStore.new }
    @user = TestUser.create!(name: "Alice")
  end

  def test_token_balance
    assert_equal 0, @user.token_balance
    @user.grant_tokens!(1000, reason: :signup)
    assert_equal 1000, @user.token_balance
  end

  def test_grant_and_deduct
    @user.grant_tokens!(500, reason: :trial)
    @user.deduct_tokens!(200, reason: :render)
    assert_equal 300, @user.token_balance
  end

  def test_spend_tokens_on
    Ask::Tokens.activity(:job, cost: 50)
    @user.grant_tokens!(1000, reason: :start)
    @user.spend_tokens_on!(:job) { "done" }
    assert_equal 950, @user.token_balance
  end

  def test_token_wallet_persisted
    @user.grant_tokens!(100, reason: :init)
    wallet = Ask::Tokens::TokenWallet.find_by(owner: @user)
    assert wallet
    assert_equal 100, wallet.balance
  end

  def test_token_transactions_association
    @user.grant_tokens!(100, reason: :a)
    @user.deduct_tokens!(10, reason: :b)
    assert_equal 2, @user.token_transactions.count
  end

  def test_ask_token_wallet_returns_poro
    w = @user.ask_token_wallet
    assert_kind_of Ask::Tokens::Wallet, w
  end

  def test_has_tokens_for
    @user.grant_tokens!(100, reason: :x)
    assert @user.has_tokens_for?(50)
    refute @user.has_tokens_for?(200)
  end

  def test_try_deduct_tokens_returns_false
    assert_equal false, @user.try_deduct_tokens!(100, reason: :nope)
  end

  def test_has_token_wallet_macro
    macro_user = MacroUser.create!(name: "Macro")
    macro_user.grant_tokens!(250, reason: :signup)
    assert_equal 250, macro_user.token_balance
  end

  def test_ledger_credits_and_debits_read
    @user.grant_tokens!(1_000, reason: :trial)
    @user.deduct_tokens!(250, reason: :render)

    assert_equal 1_000, @user.token_transactions.credits.sum(:amount)
    assert_equal(-250, @user.token_transactions.debits.sum(:amount))
    assert @user.token_transactions.credits.all?(&:credit?)
    assert @user.token_transactions.debits.all?(&:debit?)
  end
end
