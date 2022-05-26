# frozen_string_literal: true

require_relative "lib/aurora_data_api/version"

Gem::Specification.new do |spec|
  spec.name = "aurora_data_api"
  spec.version = AuroraDataApi::VERSION
  spec.authors = ["HASUMI Hitoshi"]
  spec.email = ["hasumikin@gmail.com"]

  spec.summary = "A kind of ORM for Amazon Aurora Serverless v1"
  spec.description = "Assuming you are using AWS Lambda as a backend, Aurora Serverless v1 (NOT v2) as a database, and Data API as an adapter"
  spec.homepage = "https://github.com/hasumikin/aurora_data_api"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 2.7.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/hasumikin/aurora_data_api"
  spec.metadata["changelog_uri"] = "https://github.com/hasumikin/aurora_data_api/blob/master/CHANGELOG.md"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject do |f|
      (f == __FILE__) || f.match(%r{\A(?:(?:bin|test|spec|features)/|\.(?:git|travis|circleci)|appveyor)})
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "aws-sdk-rdsdataservice", "~> 1.35.0"
  spec.add_dependency "thor"
end
