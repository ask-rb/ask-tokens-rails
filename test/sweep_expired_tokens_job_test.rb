require_relative "test_helper"

class SweepExpiredTokensJobTest < Minitest::Test
  def setup
    Ask::Tokens.reset!
    Ask::Tokens.configure do |c|
      c.store = Ask::Tokens::Rails::ActiveRecordStore.new
      c.time = -> { Time.now }
    end
    Ask::Tokens::TokenTransaction.delete_all
    Ask::Tokens::TokenWallet.delete_all
    @user = TestUser.create!(name: "Alice")
    @wallet = Ask::Tokens.wallet_for(@user)
  end

  def sweep(now: Time.current)
    Ask::Tokens::Rails::SweepExpiredTokensJob.new.perform(now: now)
  end

  def test_expires_grants_past_their_window
    @wallet.grant!(100, reason: :trial, expires_at: 1.hour.ago)

    sweep

    assert_equal 0, @wallet.balance
    expiry = Ask::Tokens::TokenTransaction.expiries.last
    assert_equal(-100, expiry.amount)
    assert_equal "token_expiry", expiry.reason
    assert_equal 100, expiry.metadata["actual_expired"]
  end

  def test_leaves_live_and_unexpiring_grants_alone
    @wallet.grant!(40, reason: :live, expires_at: 1.hour.from_now)
    @wallet.grant!(60, reason: :forever)

    sweep

    assert_equal 100, @wallet.balance
    assert_equal 0, Ask::Tokens::TokenTransaction.expiries.count
  end

  def test_caps_the_expiry_at_the_current_balance
    @wallet.grant!(100, reason: :trial, expires_at: 1.hour.ago)
    @wallet.deduct!(70, reason: :spend)

    sweep

    assert_equal 0, @wallet.balance
    assert_equal(-30, Ask::Tokens::TokenTransaction.expiries.last.amount)
  end

  def test_is_idempotent
    @wallet.grant!(100, reason: :trial, expires_at: 1.hour.ago)

    sweep
    assert_equal 1, Ask::Tokens::TokenTransaction.expiries.count

    sweep
    assert_equal 1, Ask::Tokens::TokenTransaction.expiries.count
    assert_equal 0, @wallet.balance
  end

  def test_sweeps_only_the_expired_grant_when_others_are_live
    @wallet.grant!(50, reason: :expired, expires_at: 1.hour.ago)
    @wallet.grant!(80, reason: :live, expires_at: 1.hour.from_now)

    sweep

    assert_equal 80, @wallet.balance
  end

  def test_a_later_top_up_is_never_eaten_by_an_expired_grant
    @wallet.grant!(100, reason: :trial, expires_at: 1.hour.ago)
    @wallet.deduct!(90, reason: :spend)

    sweep
    assert_equal 0, @wallet.balance

    # The trial's unspent 10 is gone; the new top-up belongs to the user.
    @wallet.grant!(40, reason: :top_up)
    sweep

    assert_equal 40, @wallet.balance
    assert_equal 10, Ask::Tokens::TokenTransaction.expiries.sum(:amount).abs
  end
end
