require 'logger'

module BackgroundWorker
  class Config
    attr_reader :logger

    # Configuration includes following options:
    #   logger: what logger to user throughout
    #   enqueue_with: callback to execute the process
    #   after_exception: callback to handle exceptions (for example, error reporting service)
    #
    # eg:
    # Config.new(
    #   logger: Rails.logger,
    #   enqueue_with: -> klass, method_name, opts { Resque.enqueue(klass, method_name, opts) },
    #   after_exception: -> e { Airbrake.notify(e) }
    # )
    def initialize(attrs)
      @logger = attrs.fetch(:logger, ::Logger.new(STDOUT))
      @enqueue_with = attrs.fetch(:enqueue_with, method(:foreground_enqueue))
      @after_exception = attrs.fetch(:after_exception, method(:default_after_exception))
    end

    # Callback fired when an exception occurs
    def after_exception(e)
      @after_exception.call(e)
    end

    def foreground_enqueue(klass, method_name, opts)
      klass.perform(method_name, opts)
    end

    def default_after_exception(e)
      logger.error '** No after_exception handler installed **'
      logger.error "Exception: #{e}"
      logger.error "#{e.backtrace.join("\n")}"
    end
  end
end
