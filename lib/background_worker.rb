module BackgroundWorker
  VERSION = '0.0.1'

  require 'background_worker/base'
  require 'background_worker/persistent_state'

  def self.after_exception(&block)
    if block
      @@after_exception = block
    else
      @@after_exception
    end
  end
end
