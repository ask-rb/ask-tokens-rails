# ask-tokens-rails

ActiveRecord persistence for the [ask-tokens](https://github.com/ask-rb/ask-tokens) wallet engine.

Ships an ActiveRecord store adapter, a `has_token_wallet` macro, install generator with migrations, and an expiry sweep job.

## Installation

```ruby
# Gemfile
gem "ask-tokens-rails"
```

```sh
bundle install
rails g ask_tokens:install
rails db:migrate
```

Table names default to `ask_tokens_wallets` and `ask_tokens_transactions`. To adopt existing tables:

```ruby
Ask::Tokens::Rails.configure do |config|
  config.wallets_table = "token_wallets"
  config.transactions_table = "token_transactions"
end
```

## Usage

```ruby
class User < ApplicationRecord
  has_token_wallet
end

# Grant tokens
user.grant_tokens!(10_000, reason: :trial, expires_at: 7.days.from_now)

# Spend on an activity (charges only if the block succeeds)
user.spend_tokens_on!(:chat_message, input: "hi", output: "yo") do
  LLM.chat(...)
end

# Check balance
user.token_balance   # => 9_998

# Read the ledger
user.token_transactions.credits
user.token_transactions.debits.since(30.days.ago)

# Use the PORO wallet directly
wallet = user.ask_token_wallet
wallet.entries
wallet.used_since(30.days.ago)
```

Pass `metadata: {model_id:, provider:, input_tokens:, output_tokens:, cached_tokens:, llm_cost_usd:, multiplier:}` on a grant/deduction and the store lifts those keys into the ledger's billing columns, so model spend and margin can be summed without JSON casts.

## Scheduled jobs

`SweepExpiredTokensJob` expires grant entries whose `expires_at` has passed, removing only each grant's unspent remainder (first-to-expire-first allocation). Add an `expires_at` index if your install predates migration column v0.4.0.

```yaml
# config/recurring.yml (Solid Queue)
ask_tokens_sweep:
  class: Ask::Tokens::Rails::SweepExpiredTokensJob
  schedule: every hour
```
