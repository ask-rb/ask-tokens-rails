# frozen_string_literal: true

require "rails/generators"
require "rails/generators/migration"

module AskTokenUsage
  module Generators
    class InstallGenerator < Rails::Generators::Base
      include Rails::Generators::Migration
      source_root File.expand_path("templates", __dir__)

      desc "Creates the ask-token-usage migration and initializer"

      def self.next_migration_number(_dir)
        Time.now.utc.strftime("%Y%m%d%H%M%S")
      end

      def create_migration
        migration_template "migration.rb", "db/migrate/create_token_wallets.rb"
      end

      def create_initializer
        template "initializer.rb", "config/initializers/ask_token_usage.rb"
      end

      def show_readme
        readme "README.md" if behavior == :invoke
      end
    end
  end
end
