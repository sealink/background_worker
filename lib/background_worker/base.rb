module BackgroundWorker
  class Base

    attr_accessor :uid, :state

    def initialize(options={})
      Time.zone = Setting.time_zone

      @uid = options['uid']

      # Store state persistently, to enable status checkups & progress reporting
      @state = BackgroundWorker::PersistentState.new(@uid, options.except('uid'))
      log("Created #{self.class.to_s}")
      log("Options are: #{options.pretty_inspect}")
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
      if Time.now - @last_report > 1
        @last_report = Time.now
        state.save
      end
    end


    def report_successful(message="Finished successfully")
      state.set_completed(message, :successful)
    end


    def report_failed(message="Failed", detailed_message = nil)
      state.detailed_message = detailed_message
      state.set_completed(message, :failed)
    end


    def logger
      BackgroundWorker.logger
    end


    def log(message, options={})
      severity = options.fetch(:severity, :info)
      logger.send(severity, "uid=#{uid} #{message}")
    end


    class << self

      def get_state_of(worker_id)
        BackgroundWorker::PersistentState.get_state_of(worker_id)
      end

      # Public method to do in background...
      def perform_in_background(method_name, options={})
        method_name = method_name.to_sym
        options[:uid] ||= generate_uid(method_name)

        # Store into redis before putting job out
        BackgroundWorker::PersistentState.new(options[:uid], options.except(:uid))

        # Enqueue to the background queue
        BackgroundWorker.enqueue(self, method_name, options)

        return options[:uid]
      end


      # This method is called by the job runner
      #
      # It will just call your preferred method in the worker.
      def perform(method_name, options={})
        raise ArgumentError, ":uid is required: Options given were: #{options.inspect}" if options['uid'].blank?
        BackgroundWorker.verify_active_connections!

        # Special 'user' handling
        raise ArgumentError, ":current_user_id is required: Options given were: #{options.inspect}" if options['current_user_id'].blank?
        set_current_user(options['current_user_id'])

        worker = self.new(options)
        worker.report_progress "Task started"
        returned_data = worker.send(method_name, options)

        # If not explicitly completed, set completed now
        if !worker.state.completed
          worker.state.data.merge!(hasherize_opts(returned_data, :key_if_not_hash => :result))
          worker.report_successful
        end

      rescue Exception => e
        if worker
          worker.log("Implicit failure: Exception occurred: #{e}", severity: :error)
          worker.report_failed("An unhandled exception occurred: #{e}") if !worker.state.completed
        end
        BackgroundWorker.after_exception.call(e)

      ensure
        if worker
          worker.log "Final state: #{worker.state.data}", severity: :info
          worker.log "Job was #{worker.state.status}", severity: :info
        end
      end


      def set_current_user(current_user_id)
        Thread.current['user'] = Party.find(current_user_id)
      end


      protected

      def hasherize_opts(opts, args={})
        if opts.is_a?(Hash)
          opts
        else
          {(args[:key_if_not_hash] || :result) => opts}
        end
      end


      private

      # generates a unique identifier for this particular job.
      def generate_uid(method)
        "#{ generate_uid_name(method) }:#{ generate_uid_hash(method) }"
      end


      def generate_uid_hash(method)
        ::Digest::MD5.hexdigest("#{ self.to_s }:#{ method }:#{ rand(1 << 64) }:#{ Time.now }")
      end


      def generate_uid_name(method)
        "#{ self.to_s.underscore }/#{ method }".split('/').join(':')
      end

    end

  end
end
