# Progress reporter is used by background processes, to communicate with
# standard rails controllers.
#
# It works by storing a hash of all progress-report data in a redis value
# keyed by the worker_uid.
module BackgroundWorker
  class PersistentState

    attr_accessor :message, :detailed_message, :status, :completed, :data

    def initialize(worker_uid, data)
      @message = "Waiting for task to queue..."
      @status = :processing
      @completed = false

      @worker_uid = worker_uid
      @data = data
      save
    end


    def set_completed(message, status)
      self.status = status
      self.message = message

      self.completed = true
      save
    end


    # Save persistently (well for an hour at least)
    def save
      Rails.cache.write(@worker_uid, generate_persistent_hash, :expires_in => 1.hour)
    end


    # Get a report out the queue
    # (was .get_report, then .progress)
    def self.get_state_of(worker_uid)
      Rails.cache.read(worker_uid)
    end


    private

    # Generate a hash of this objects state
    #  (representing this status progress report)
    def generate_persistent_hash
      {
        :message => message,
        :detailed_message => detailed_message,
        :status => status,
        :completed => completed,
        :data => data
      }
    end
  end
end
