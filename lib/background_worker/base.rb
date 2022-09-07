require 'background_worker/uid'
require 'background_worker/persistent_state'
require 'background_worker/worker_execution'

module BackgroundWorker
  class Base
    attr_accessor :uid, :state

    def initialize(options = {})
      @uid = options[:uid]

      # Store state persistently, to enable status checkups & progress reporting
      @state = BackgroundWorker::PersistentState.new(@uid, options.except(:uid))
      log("Created #{self.class}")
      log("Options are: #{options.inspect}")
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

    def report_failed(message = 'Failed', detailed_message = nil)
      state.detailed_message = detailed_message
      state.set_completed(message, :failed)
    end

    def logger
      BackgroundWorker.logger
    end

    def log(message, options = {})
      severity = options.fetch(:severity, :info)
      logger.send(severity, "uid=#{uid} #{message}")
    end

    class << self
      attr_accessor :queue
      def get_state_of(worker_id)
        BackgroundWorker::PersistentState.get_state_of(worker_id)
      end

      # Public method to do in background...
      def perform_later(method_name, options = {})
        opts = options.symbolize_keys

        method_name = method_name.to_sym
        opts[:uid] ||= BackgroundWorker::Uid.new(to_s, method_name).generate

        # Store into shared-cache before kicking job off
        BackgroundWorker::PersistentState.new(opts[:uid], opts.except(:uid))

        # Enqueue to the background queue
        BackgroundWorker.enqueue(self, method_name, opts)

        opts[:uid]
      end

      # This method is called by the job runner
      #
      # It will just call your preferred method in the worker.
      def perform_now(method_name, options = {})
        BackgroundWorker.verify_active_connections! if BackgroundWorker.config.backgrounded

        worker = new(options)
        execution = WorkerExecution.new(worker, method_name, options)
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
