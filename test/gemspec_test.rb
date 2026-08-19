require_relative "test_helper"

class GemspecTest < Minitest::Test
  def test_gemspec_is_valid
    spec = Gem::Specification.load(File.expand_path("../ask-tokens-rails.gemspec", __dir__))
    assert spec
    assert_kind_of Gem::Specification, spec
    assert spec.name.start_with?("ask-")
    assert spec.version.to_s > "0"
  end

  def test_depends_on_ask_tokens
    spec = Gem::Specification.load(File.expand_path("../ask-tokens-rails.gemspec", __dir__))
    dep = spec.dependencies.find { |d| d.name == "ask-tokens" }
    assert dep, "must depend on ask-tokens"
  end

  def test_depends_on_rails
    spec = Gem::Specification.load(File.expand_path("../ask-tokens-rails.gemspec", __dir__))
    dep = spec.dependencies.find { |d| d.name == "rails" }
    assert dep, "must depend on rails"
  end
end
