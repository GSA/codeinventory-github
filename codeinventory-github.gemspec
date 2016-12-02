# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'codeinventory/github'

Gem::Specification.new do |spec|
  spec.name          = "codeinventory-github"
  spec.version       = CodeInventory::GitHub::VERSION
  spec.authors       = ["Jeff Fredrickson"]
  spec.email         = ["jeffrey.fredrickson@gsa.gov"]

  spec.summary       = %q{Harvests project metadata from YAML or JSON files in GitHub repositories.}
  spec.description   = %q{A plugin for the CodeInventory gem that harvests project metadata from YAML or JSON files in GitHub repositories.}
  spec.homepage      = "https://github.com/GSA/codeinventory-github"
  spec.license       = "CC0-1.0"

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.13"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "minitest", "~> 5.0"
  spec.add_development_dependency "webmock", "~> 2.1"
  spec.add_development_dependency "pry", "~> 0.10"

  spec.add_runtime_dependency "codeinventory", "~> 0.1.0"
  spec.add_runtime_dependency "octokit", "~> 4.6"
end
