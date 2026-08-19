# frozen_string_literal: true

require "active_job"

module Ask
  module Tokens
    module Rails
      # Expire grant entries whose +expires_at+ has passed. Scheduled as a
      # recurring job (Solid Queue cron, Sidekiq Cron, etc.):
      #
      #   # config/recurring.yml
      #   ask_tokens_sweep:
      #     class: Ask::Tokens::Rails::SweepExpiredTokensJob
      #     schedule: "every 1 hour"
      #
      # For each expired grant, the actual amount removed is capped to the
      # wallet's current balance (myrr approximation — correct for most
      # grant-heavy usage patterns; perfect accuracy requires FIFO allocation
      # which is a future option).
      #
      class SweepExpiredTokensJob < ActiveJob::Base
        queue_as :default

        def perform(now: Time.current)
          Ask::Tokens::TokenTransaction
            .grants
            .where("expires_at IS NOT NULL AND expires_at <= ?", now)
            .where.not(entry_type: "expiry")
            .where("id NOT IN (SELECT source_transaction_id FROM token_transactions WHERE entry_type = ?)", "expiry")
            .find_each do |grant|
              sweep_grant(grant)
            end
        end

        private

        def sweep_grant(grant)
          wallet = grant.token_wallet
          return unless wallet

          wallet.with_lock do
            remaining = grant.amount - already_expired_amount(grant)
            return if remaining <= 0

            actual = [remaining, wallet.balance].min
            return if actual <= 0

            Ask::Tokens::TokenTransaction.create!(
              token_wallet_id: wallet.id,
              entry_type: "expiry",
              amount: -actual,
              reason: "token_expiry",
              balance: wallet.balance - actual,
              metadata: {
                source_transaction_id: grant.id,
                expired_amount: remaining,
                actual_expired: actual
              },
              created_at: now
            )

            wallet.update_column(:balance, wallet.balance - actual)
          end
        end

        def already_expired_amount(grant)
          Ask::Tokens::TokenTransaction
            .where(token_wallet_id: grant.token_wallet_id, entry_type: "expiry")
            .where("metadata->>'source_transaction_id' = ?", grant.id.to_s)
            .sum(:amount)
            .abs
        end
      end
    end
  end
end
