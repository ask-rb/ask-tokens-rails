require_relative "lib/ask/token_usage/rails/version"

Gem::Specification.new do |spec|
  spec.name = "ask-token-usage-rails"
  spec.version = Ask::TokenUsage::Rails::VERSION
  spec.authors = ["Kaka Ruto"]
  spec.email = ["kaka@myrrlabs.com"]

  spec.summary = "ActiveRecord persistence for the ask-token-usage wallet engine"
  spec.description = "Adds an ActiveRecord-backed wallet store, has_token_wallet concern, token wallet/transaction models, an install generator with migrations, and an expiry sweep job to any Rails app using ask-token-usage."
  spec.homepage = "https://github.com/ask-rb/ask-token-usage-rails"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.2"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/ask-rb/ask-token-usage-rails"
  spec.metadata["changelog_uri"] = "https://github.com/ask-rb/ask-token-usage-rails/blob/main/CHANGELOG.md"

  spec.require_paths = ["lib"]
  spec.files = Dir["lib/**/*", "LICENSE", "README.md", "CHANGELOG.md"]

  spec.add_dependency "ask-token-usage", ">= 0.1.0"
  spec.add_dependency "rails", ">= 7.0"

  spec.add_development_dependency "minitest", "~> 5.25"
  spec.add_development_dependency "rake", "~> 13.0"
  spec.add_development_dependency "sqlite3"
end
