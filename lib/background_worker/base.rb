require "active_support/callbacks"
require 'background_worker/persistent_state'
require 'background_worker/worker_execution'
require 'background_worker/logging'
require 'background_worker/state'

module BackgroundWorker
  class Base
    include ActiveSupport::Callbacks
    include BackgroundWorker::Logging
    include BackgroundWorker::State
    attr_accessor :job_id, :options
    define_callbacks :perform
    define_callbacks :enqueue

    def initialize(options = {})
      @options = options.symbolize_keys
      @job_id = @options[:job_id] || SecureRandom.uuid

      log("Created #{self.class}")
      log("Options are: #{@options.inspect}")
    end

    def perform_now(options)
      run_callbacks :perform do
        perform(options)
      end
    end

    def enqueue(klass)
      run_callbacks :enqueue do
        BackgroundWorker.enqueue(klass, options.merge(job_id: job_id))
      end
    end

    class << self
      attr_reader :queue

      # Public method to do in background...
      def perform_later(options = {})
        worker = new(options)
        # Enqueue to the background queue
        worker.enqueue(self)
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

      def before_perform(*filters, &blk)
        set_callback(:perform, :before, *filters, &blk)
      end

      def after_perform(*filters, &blk)
        set_callback(:perform, :after, *filters, &blk)
      end

      def before_enqueue(*filters, &blk)
        set_callback(:enqueue, :before, *filters, &blk)
      end

      def after_enqueue(*filters, &blk)
        set_callback(:enqueue, :after, *filters, &blk)
      end
    end
  end
end
