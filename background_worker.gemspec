# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'background_worker/version'

Gem::Specification.new do |spec|
  spec.name          = 'background_worker'
  spec.version       = BackgroundWorker::VERSION
  spec.authors       = ['Michael Noack', 'Adam Davies', 'Alessandro Berardi']
  spec.email         = ['development@travellink.com.au', 'adzdavies@gmail.com', 'berardialessandro@gmail.com']
  spec.summary       = 'Background worker abstraction with status updates'
  spec.description   = 'See README for full details'
  spec.homepage      = 'http://github.com/sealink/background_worker'
  spec.license       = 'MIT'

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ['lib']

  spec.add_development_dependency 'bundler'
  spec.add_development_dependency 'rake'
  spec.add_development_dependency 'rubocop'
end
