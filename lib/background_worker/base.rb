require 'background_worker/persistent_state'
require 'background_worker/worker_execution'

module BackgroundWorker
  class Base
    attr_accessor :job_id, :state, :options

    def initialize(options = {})
      @options = options.symbolize_keys
      @job_id = @options[:job_id] || SecureRandom.uuid

      # Store state persistently, to enable status checkups & progress reporting
      @state = BackgroundWorker::PersistentState.new(job_id, @options)
      log("Created #{self.class}")
      log("Options are: #{@options.inspect}")
    end

    def perform
      raise AbstractError, 'Must be implemented in Job Class'
    end

    # Report progress...
    def report_progress(message)
      state.message = message
      state.save
    end

    # Report a minor progress -- may get called a lot, so don't save it so often
    def report_minor_progress(message)
      state.message = message

      # Only report minor events once per second
      @last_report ||= Time.now - 2
      time_elapsed =  Time.now - @last_report
      return unless time_elapsed > 1

      @last_report = Time.now
      state.save
    end

    def report_successful(message = 'Finished successfully')
      state.set_completed(message, :successful)
    end

    def before_perform
      yield self if block_given?
    end

    def after_perform
      yield self if block_given?
    end

    def before_enqueue
      yield self if block_given?
    end

    def after_enqueue
      yield self if block_given?
    end

    def report_failed(message = 'Failed', detailed_message = nil)
      state.detailed_message = detailed_message
      state.set_completed(message, :failed)
    end

    def logger
      BackgroundWorker.logger
    end

    def log(message, options = {})
      severity = options.fetch(:severity, :info)
      logger.send(severity, "job_id=#{job_id} #{message}")
    end

    class << self
      attr_reader :queue
      def get_state_of(job_id)
        BackgroundWorker::PersistentState.get_state_of(job_id)
      end

      # Public method to do in background...
      def perform_later(options = {})
        worker = new(options)
        # Enqueue to the background queue
        worker.before_enqueue
        BackgroundWorker.enqueue(self, worker.options.merge(job_id: worker.job_id))
        worker.after_enqueue
        worker.job_id
      end

      # This method is called by the job runner
      #
      # It will just call your preferred method in the worker.
      def perform_now(options = {})
        BackgroundWorker.verify_active_connections! if BackgroundWorker.config.backgrounded

        worker = new(options)
        execution = WorkerExecution.new(worker, options)
        execution.call
      ensure
        BackgroundWorker.release_connections! if BackgroundWorker.config.backgrounded
      end

      def queue_as(queue = nil)
        @queue = queue&.to_sym || :default
      end
    end
  end
end
