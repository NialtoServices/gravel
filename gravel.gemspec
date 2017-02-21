# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'gravel/constants'

Gem::Specification.new do |spec|
  spec.name          = 'gravel'
  spec.version       = Gravel::VERSION
  spec.authors       = ['Nialto Services']
  spec.email         = ['support@nialtoservices.co.uk']

  spec.summary       = %q{Unified Push Notifications}
  spec.homepage      = 'https://github.com/nialtoservices/gravel'
  spec.license       = 'MIT'

  spec.files         = `git ls-files -z`.split("\x0")
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ['lib']

  spec.add_dependency 'jwt',       '~> 1.5'
  spec.add_dependency 'net-http2', '~> 0.14.1'

  spec.add_development_dependency 'bundler', '~> 1.11'
  spec.add_development_dependency 'rake',    '~> 10.0'
  spec.add_development_dependency 'rspec',   '~> 3.0'
end
