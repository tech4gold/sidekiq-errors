require File.expand_path('../lib/sidekiq/errors/version', __FILE__)

Gem::Specification.new do |spec|
  spec.name          = "sidekiq-errors"
  spec.version       = Sidekiq::Errors::VERSION
  spec.summary       = %q{better manage sidekiq retries}
  spec.description   = %q{relatively simple but more efficient way to manage a large number of sidekiq retries.}
  spec.authors       = ["christopher holt"]
  spec.email         = "chris@tech4gold.com"
  spec.homepage      = "https://github.com/tech4gold/sidekiq-errors/"
  spec.license       = "MIT"
  spec.files         = `git ls-files`.split($\)

  spec.add_dependency 'sidekiq', '>= 3.2', '~> 3'

end
