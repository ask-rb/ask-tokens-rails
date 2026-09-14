## [0.4.0] — 2026-09-14

### Added

- **Billing-detail columns on the ledger.** `model_id`, `provider`,
  `input_tokens`, `output_tokens`, `cached_tokens`, `llm_cost_usd`, and
  `multiplier` — already lifted out of `metadata` by the ActiveRecord store —
  are now in the install migration, so ledgers can be summed and grouped
  (model spend, margin) without JSON casts. The columns are optional: the
  store intersects the extraction keys with the table's actual columns, so
  installs created before this release keep the detail in `metadata`.
  Existing installs can add the columns with the equivalent migration.
- **`credits` scope and `debit?`/`credit?` predicates** on the ledger model,
  matching the `debits`/`grants` scopes.
- **`has_token_wallet` macro.** Including `Ask::Tokens::Rails::HasTokenWallet`
  still works; the railtie also makes the documented `has_token_wallet` macro
  available on every model.
- **`expires_at` index** on the transactions table, for the sweep job.

### Fixed

- **`SweepExpiredTokensJob` never loaded and had a broken query.** The job is
  now required by the railtie, and its grant lookup no longer hardcodes the
  legacy `token_transactions` table or a nonexistent `source_transaction_id`
  column (the source grant lives in `metadata`).
- **Expiry no longer eats a later top-up.** The sweep replays the wallet's
  ledger first-to-expire-first and removes only each expired grant's unspent
  remainder, instead of capping at whatever the wallet balance happens to be.
  Repeated runs are idempotent.

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
