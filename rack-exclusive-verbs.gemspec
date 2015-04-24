# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'rack/exclusive_verbs'

Gem::Specification.new do |spec|
  spec.name          = "rack-exclusive-verbs"
  spec.version       = Rack::ExclusiveVerbs.VERSION
  spec.authors       = ["Steve Jabour"]
  spec.email         = ["steve@jabour.me"]
  spec.license       = 'MIT'

  spec.summary       = %q{Rack middleware implementing an IP whitelist of HTTP verbs.}
  spec.description   = %q{Rack middleware implementing an IP whitelist of HTTP verbs.}
  spec.homepage      = "https://github.com/atsjj/rack-exclusive-verbs"

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.require_paths = ["lib"]

  spec.add_dependency 'rack', '>= 0.9.1'

  spec.add_development_dependency "bundler", "~> 1.9"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec", "~> 3.2"
end
