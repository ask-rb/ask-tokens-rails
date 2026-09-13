## [0.3.0] — 2026-09-14

### Changed



- **Default table names are now gem-prefixed: `ask_tokens_wallets` and

  `ask_tokens_transactions`.** They can no longer collide with an app's own

  ledger, so no app configuration is needed. To keep the old names (or adopt

  existing tables), configure them:



  ```ruby

  Ask::Tokens::Rails.configure do |config|

    config.wallets_table = "token_wallets"

    config.transactions_table = "token_transactions"

  end

  ```



  Existing installs must either set the configuration above or rename their

  tables in a migration.



### Added



- `Ask::Tokens::Rails.configure` and `reset_config!` — configurable wallet

  and transaction table names, honoured by the models and the install

  generator.



# Changelog

## [0.1.0] - 2026-08-19

### Added
- `has_token_wallet` concern for any ActiveRecord model.
- `Ask::TokenUsage::TokenWallet` (polymorphic owner + cached balance).
- `Ask::TokenUsage::TokenTransaction` append-only ledger (immutable).
- `Ask::TokenUsage::Rails::ActiveRecordStore` implementing the core Store port.
- `rails g ask_token_usage:install` — migration (`token_wallets`, `token_transactions`) + initializer.
- `SweepExpiredTokensJob` for expiring past-due grant entries.
- Automatic store swap via Railtie — no manual wiring required.
- Standard ask-gem infrastructure: CI, rubocop, overcommit.
