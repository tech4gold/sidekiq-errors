begin
  require "sidekiq/web"
rescue LoadError
  # client-only usage
end

require "sidekiq/api"
require "sidekiq/errors/version"
require "sidekiq/errors/web_extension"

module Sidekiq

  def self.errors_max_count=(value)
    @errors_max_count = value
  end

  def self.errors_max_count
    return 10_000 if @errors_max_count.nil?

    @errors_max_count
  end

end

if defined?(Sidekiq::Web)
  Sidekiq::Web.register Sidekiq::Errors::WebExtension
  Sidekiq::Web.tabs["Errors"] = "errors"
end
