require 'background_worker/version'
require 'background_worker/base'
require 'background_worker/persistent_state'

module BackgroundWorker
  def self.after_exception(&block)
    if block
      @@after_exception = block
      return
    end

    @@after_exception ||= lambda  do |e|
      logger.error '** No after_exception handler installed **'
      logger.error "Exception: #{e}"
      logger.error "#{e.backtrace.join("\n")}"
    end
  end

  # Provide your own background worker enqueue implementation
  #   eg:
  #  Resque.enqueue(klass, method_name, options)
  def self.enqueue(klass, method_name, options)
    if @@enqueue_with
      @@enqueue_with.call(klass, method_name, options)
    else
      # No backgrounded by default
      klass.perform(method_name, options)
    end
  end

  def self.enqueue_with(&block)
    @@enqueue_with = block
  end

  def self.logger
    @@logger ||= Logger.new(STDOUT)
  end

  def self.logger=(logger)
    @@logger = logger
  end

  def self.verify_active_connections!
    Rails.cache.reconnect if defined?(Rails)
    ActiveRecord::Base.verify_active_connections! if defined?(ActiveRecord)
  end
end
