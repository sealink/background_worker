require 'background_worker/version'
require 'background_worker/base'
require 'background_worker/persistent_state'

module BackgroundWorker
  def self.after_exception(&block)
    if block
      @@after_exception = block
    else
      @@after_exception if defined?(@@after_exception)
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
end
