require 'background_worker/version'
require 'background_worker/uid'
require 'background_worker/base'
require 'background_worker/persistent_state'

module BackgroundWorker
  def self.enqueue(klass, method_name, options)
    if enqueue_with
      enqueue_with.call(klass, method_name, options)
    else
      # No backgrounded by default
      klass.perform(method_name, options)
    end
  end

  class << self
    # Provide a logger
    attr_writer :logger

    attr_writer :after_exception

    # Provide your own background worker enqueue implementation
    #
    # eg:
    # BackgroundWorker.enqueue_with = -> klass, method_name, options {
    #   Resque.enqueue(klass, method_name, options)
    # }
    attr_writer :enqueue_with
  end

  def self.logger
    @logger ||= Logger.new(STDOUT)
  end

  def self.verify_active_connections!
    Rails.cache.reconnect if defined?(Rails)
    ActiveRecord::Base.verify_active_connections! if defined?(ActiveRecord)
  end

  def self.after_exception(&_block)
    @after_exception ||= lambda  do |e|
      logger.error '** No after_exception handler installed **'
      logger.error "Exception: #{e}"
      logger.error "#{e.backtrace.join("\n")}"
    end
  end
end
