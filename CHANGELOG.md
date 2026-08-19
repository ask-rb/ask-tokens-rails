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
