# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'apique/version'

Gem::Specification.new do |spec|
  spec.name          = "apique"
  spec.version       = Apique::VERSION
  spec.authors       = ["Sergey Baev"]
  spec.email         = ["tinbka@gmail.com"]

  spec.summary       = %q{Rails CRUD API replacement}
  spec.description   = %q{Apique modules replace tons of API cotrollers code which makes trivial actions including searching and CRUD, and provides front-end with thought-out errors and explanations.}
  spec.homepage      = "https://github.com/tinbka/apique"

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  #spec.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.11"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec", "~> 3.3"
  
  spec.add_dependency "cancancan"
  spec.add_dependency "rails"
end
