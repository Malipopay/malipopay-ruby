# frozen_string_literal: true

require_relative "lib/malipopay/version"

Gem::Specification.new do |spec|
  spec.name          = "malipopay"
  spec.version       = Malipopay::VERSION
  spec.authors       = ["Lockwood Technology Ltd"]
  spec.email         = ["developers@malipopay.co.tz"]

  spec.summary       = "Official Ruby SDK for the Malipopay payment platform"
  spec.description   = "Ruby client library for integrating with Malipopay payment APIs. " \
                        "Supports mobile money collections, disbursements, invoicing, " \
                        "SMS, customer management, and more."
  spec.homepage      = "https://github.com/malipopay/malipopay-ruby"
  spec.license       = "MIT"

  spec.required_ruby_version = ">= 3.0.0"

  spec.metadata["homepage_uri"]    = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"]   = "#{spec.homepage}/blob/main/CHANGELOG.md"
  spec.metadata["documentation_uri"] = "https://docs.malipopay.co.tz"

  spec.files = Dir.chdir(__dir__) do
    `git ls-files -z`.split("\x0").reject do |f|
      (File.expand_path(f) == __FILE__) ||
        f.start_with?("spec/", "examples/", ".git", ".github")
    end
  end

  spec.require_paths = ["lib"]

  spec.add_dependency "faraday", "~> 2.0"
  spec.add_dependency "faraday-retry", "~> 2.0"

  spec.add_development_dependency "bundler", "~> 2.0"
  spec.add_development_dependency "rake", "~> 13.0"
  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_development_dependency "webmock", "~> 3.0"
  spec.add_development_dependency "rubocop", "~> 1.0"
end
