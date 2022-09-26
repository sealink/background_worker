require 'active_support/concern'

module BackgroundWorker
  module LoggingConcern
    extend ActiveSupport::Concern
    attr_reader :job_id

    def logger
      BackgroundWorker.logger
    end

    def log(message, options = {})
      severity = options.fetch(:severity, :info)
      logger.send(severity, "job_id=#{job_id} #{message}")
    end
  end
end
