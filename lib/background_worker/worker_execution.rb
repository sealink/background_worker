module BackgroundWorker
  class WorkerExecution
    attr_reader :worker, :method_name, :options

    def initialize(worker, method_name, options)
      fail ArgumentError, "'uid' is required to identify worker" unless options['uid'].present?
      @worker = worker
      @method_name = method_name
      @options = options
    end

    def call
      worker.send(method_name, options)
      report_implicitly_successful unless completed?

    rescue StandardError => e
      log_worker_error(e)
      BackgroundWorker.after_exception.call(e)

    ensure
      log_worker_finality
    end

    private

    def completed?
      worker.state.completed
    end

    def report_implicitly_successful
      worker.report_successful
    end

    def log_worker_error(e)
      worker.log("Implicit failure: Exception: #{e}", severity: :error)
      worker.report_failed("An unhandled error occurred: #{e}") unless completed?
    end

    def log_worker_finality
      worker.log "Final state: #{worker.state.data}"
      worker.log "Job was #{worker.state.status}"
    end
  end
end
