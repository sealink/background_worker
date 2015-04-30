# Generates a unique identifier for a particular job identified by class_name/method
module BackgroundWorker
  class Uid
    attr_reader :class_name, :method

    def initialize(class_name, method)
      @class_name = class_name
      @method = method
    end

    def generate
      "#{generate_uid_name}:#{generate_uid_hash}"
    end

    private

    def generate_uid_hash
      ::Digest::MD5.hexdigest("#{class_name}:#{method}:#{rand(1 << 64)}:#{Time.now}")
    end

    def generate_uid_name
      "#{class_name.underscore}/#{method}".split('/').join(':')
    end
  end
end
