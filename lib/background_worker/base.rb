module BackgroundWorker
  class Base

    attr_accessor :uid, :state
    cattr_accessor :logger

    delegate :report_successful, :report_failed, :to => :state


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


    def log(message, severity = :info)
      self.class.log("#{@uid}: #{message}", severity)
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

        Resque.enqueue(self, method_name, options)

        return options[:uid]
      end


      def rescue_reconnect
        Resque.redis.client.disconnect
        Resque.redis.client.reconnect
        Rails.cache.reconnect
      end


      # This method is called by Resque
      #
      # It will just call your preferred method in the worker.
      def perform(method_name, options={})
        rescue_reconnect if defined?(Resque)
        ActiveRecord::Base.verify_active_connections!

        raise ArgumentError, ":uid is required: Options given were: #{options.inspect}" if options['uid'].blank?
        setup_logger(method_name)
        raise ArgumentError, ":current_user_id is required: Options given were: #{options.inspect}" if options['current_user_id'].blank?
        set_current_user(options['current_user_id'])

        worker = self.new(options)
        worker.report_progress "Task started"

        returned_data = worker.send(method_name, options)

        worker.log "returned data : #{returned_data.inspect}"
        worker.log "completed : #{worker.state.completed}"
        if !worker.state.completed
          worker.log "data : #{worker.state.data}"
          worker.state.data.merge!(hasherize_opts(returned_data, :key_if_not_hash => :result))
          worker.log "data : #{worker.state.data}"
          worker.report_successful
          worker.log "report_sucessful"
        end

      rescue Exception => e
        puts "ERROR: #{e} \n #{e.backtrace.join("\n")}"
        if logger
          log("#{options['uid']}: Exception: #{e}", :error)
          log("#{options['uid']}: Invalid Record: #{e.record.errors.full_messages.to_sentence}", :error) if e.is_a?(ActiveRecord::RecordInvalid)
          log("#{options['uid']}: #{e.backtrace.join("\n")}", :error)
        end

        BackgroundWorker.after_exception.call(e) if BackgroundWorker.after_exception

        if worker && !worker.state.completed
          worker.report_failed "An unhandled exception occurred: #{e}"
        end
      end

      # LEGACY METHOD -- use instead of Resque.enqueu if you wanna spawn later...
      # Fork off, and do some work!
      #
      # Tell a spawning worker class to instantiate itself, and run a method
      def forked_send(method_name, options={})
        worker_name = "#QT-WRK# #{self}::#{method_name}"
         
        # Fork off...
        #
        # Note: exceptions are trapped in here.
        worker.spawn(:kill => true, :method => :fork, :argv => worker_name, :nice => 5) do
          worker.perform(method_name, options)
        end
      end


      # Setup logger
      #  - is ok as a class variable, as we should be forked out
      def setup_logger(method)
        log_dir = "#{Rails.root.to_s}/log/background_jobs"
        Dir.mkdir(log_dir) unless File.exist?(log_dir)

        file_name = generate_uid_name(method)

        # TODO: Issue here -- it seems to switch out progress reports -- so a web servers log file???
        @@logger = ActiveSupport::BufferedLogger.new(log_dir + "/#{file_name}")
      end


      def log(message, severity = :info)
        logger.send(severity, "[#{Time.current.xmlschema}] #{message}")
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
