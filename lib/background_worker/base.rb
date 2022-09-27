require 'background_worker/persistent_state'
require 'background_worker/worker_execution'
require 'background_worker/logging'
require 'background_worker/state'

module BackgroundWorker
  class Base
    include BackgroundWorker::Logging
    include BackgroundWorker::State
    attr_accessor :job_id, :options

    def initialize(options = {})
      @options = options.symbolize_keys
      @job_id = @options[:job_id] || SecureRandom.uuid

      log("Created #{self.class}")
      log("Options are: #{@options.inspect}")
    end

    def perform
      raise AbstractError, 'Must be implemented in Job Class'
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

    class << self
      attr_reader :queue

      # Public method to do in background...
      def perform_later(options = {})
        worker = new(options)
        # Enqueue to the background queue
        worker.before_enqueue
        BackgroundWorker.enqueue(self, worker.options.merge(job_id: worker.job_id))
        worker.after_enqueue
        worker
      end

      # This method is called by the job runner
      def perform_now(options = {})
        BackgroundWorker.verify_active_connections! if BackgroundWorker.config.backgrounded

        worker = new(options)
        execution = WorkerExecution.new(worker, options)
        execution.call
        worker
      ensure
        BackgroundWorker.release_connections! if BackgroundWorker.config.backgrounded
      end

      def queue_as(queue = nil)
        @queue = queue&.to_sym || :default
      end
    end
  end
end
