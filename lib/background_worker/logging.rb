require 'active_support/concern'

module BackgroundWorker
  module Logging
    extend ActiveSupport::Concern

    def logger
      BackgroundWorker.logger
    end

    def log(message, options = {})
      severity = options.fetch(:severity, :info)
      logger.send(severity, "job_id=#{job_id} #{message}")
    end
  end
end
