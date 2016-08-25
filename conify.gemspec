# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'conify/version'

Gem::Specification.new do |spec|
  spec.name          = "conify"
  spec.version       = Conify::VERSION
  spec.authors       = ["Ben Whittle"]
  spec.email         = ["benwhittle31@gmail.com"]
  spec.summary       = "A gem to help SaaS tools integrate their services with Conflux"
  spec.homepage      = "https://www.github.com/GoConflux/conify"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "bin"
  spec.executables   = ["conify"]
  spec.require_paths = ["lib"]

  spec.add_development_dependency "rails", "~> 4.2"
  spec.add_development_dependency "bundler", "~> 1.11"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_development_dependency "pry"
end
