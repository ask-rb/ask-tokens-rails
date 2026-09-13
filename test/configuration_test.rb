# frozen_string_literal: true

require_relative "test_helper"

class ConfigurationTest < Minitest::Test
  def setup
    Ask::Tokens::Rails.reset_config!
  end

  def teardown
    Ask::Tokens::Rails.reset_config!
  end

  def test_defaults_are_gem_prefixed_so_they_never_collide
    assert_equal "ask_tokens_wallets", Ask::Tokens::Rails.config.wallets_table
    assert_equal "ask_tokens_transactions", Ask::Tokens::Rails.config.transactions_table
    assert_equal "ask_tokens_wallets", Ask::Tokens::TokenWallet.table_name
    assert_equal "ask_tokens_transactions", Ask::Tokens::TokenTransaction.table_name
  end

  def test_configured_names_are_used_by_the_models
    Ask::Tokens::Rails.configure do |config|
      config.wallets_table = "token_wallets"
      config.transactions_table = "token_transactions"
    end

    assert_equal "token_wallets", Ask::Tokens::TokenWallet.table_name
    assert_equal "token_transactions", Ask::Tokens::TokenTransaction.table_name
  end
end
