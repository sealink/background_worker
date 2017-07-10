require 'background_worker/version'
require 'background_worker/config'
require 'background_worker/base'

module BackgroundWorker
  # Configure worker
  #
  # eg:
  # BackgroundWorker.configure(
  #   logger: Rails.logger,
  #   enqueue_with: -> klass, method_name, opts { Resque.enqueue(klass, method_name, opts) },
  #   after_exception: -> e { Airbrake.notify(e) }
  # )
  def self.configure(options)
    @config = Config.new(options)
  end

  def self.enqueue(klass, method_name, options)
    config.enqueue_with.call(klass, method_name, options)
  end

  def self.logger
    config.logger
  end

  def self.verify_active_connections!
    Rails.cache.reconnect if defined?(Rails)
    if defined?(ActiveRecord) && ActiveRecord::VERSION::MAJOR == 3
      ActiveRecord::Base.verify_active_connections!
    end
  end

  def self.release_connections!
    if defined?(ActiveRecord) && ActiveRecord::VERSION::MAJOR == 4
      ActiveRecord::Base.clear_all_connections!
    end
  end

  def self.after_exception(e)
    config.after_exception(e)
  end

  def self.config
    fail 'Not configured!' unless @config
    @config
  end

end
