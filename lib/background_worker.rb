require 'background_worker/version'
require 'background_worker/config'
require 'background_worker/base'

module BackgroundWorker
  # Configure worker
  #
  # eg:
  # BackgroundWorker.configure(
  #   logger: Rails.logger,
  #   enqueue_with: -> klass, opts { Resque.enqueue(klass, opts) },
  #   after_exception: -> e { Airbrake.notify(e) }
  # )
  def self.configure(options)
    @config = Config.new(options)
  end

  def self.enqueue(klass, options)
    config.enqueue_with.call(klass, options)
  end

  def self.logger
    config.logger
  end

  def self.verify_active_connections!
    if defined?(Rails)
      Rails.cache.reconnect if Rails.cache.respond_to?(:reconnect)
      Rails.cache.redis.close if Rails.cache.respond_to?(:redis)
    end
  end

  def self.release_connections!
    ActiveRecord::Base.clear_all_connections!
  end

  def self.after_exception(e)
    config.after_exception(e)
  end

  def self.config
    fail 'Not configured!' unless @config
    @config
  end

end
