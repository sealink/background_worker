require 'active_support/concern'

module BackgroundWorker
  module State
    extend ActiveSupport::Concern
    attr_accessor :state

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

    def state
      # Store state persistently, to enable status checkups & progress reporting
      options ||= arguments.first || {}
      @state ||= BackgroundWorker::PersistentState.new(job_id, options)
    end

    module ClassMethods
      def get_state_of(job_id)
        BackgroundWorker::PersistentState.get_state_of(job_id)
      end
    end
  end
end
