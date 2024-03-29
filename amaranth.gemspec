# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'amaranth/version'

Gem::Specification.new do |spec|
  spec.name          = "amaranth"
  spec.version       = Amaranth::VERSION
  spec.authors       = ["Micah Geisel"]
  spec.email         = ["micah@botandrose.com"]

  spec.summary       = "Library for accessing the Amara REST API"
  spec.homepage      = "https://github.com/botandrose/amaranth"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "rake"
  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_development_dependency "webmock", "~> 2.0"
end
