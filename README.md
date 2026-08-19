# ask-token-usage-rails

ActiveRecord persistence for the [ask-token-usage](https://github.com/ask-rb/ask-token-usage) wallet engine.

Ships an ActiveRecord store adapter, a `has_token_wallet` concern, install generator with migrations, and an expiry sweep job.

## Installation

```ruby
# Gemfile
gem "ask-token-usage-rails"
```

```sh
bundle install
rails g ask_token_usage:install
rails db:migrate
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

# Use the PORO wallet directly
wallet = user.ask_token_wallet
wallet.entries
wallet.used_since(30.days.ago)
```

## Scheduled jobs

`SweepExpiredTokensJob` expires grant entries whose `expires_at` has passed.

```yaml
# config/recurring.yml (Solid Queue)
ask_token_usage_sweep:
  class: Ask::TokenUsage::Rails::SweepExpiredTokensJob
  schedule: "every 1 hour"
```
