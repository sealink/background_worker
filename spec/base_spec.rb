require 'spec_helper'

require 'active_support/core_ext/hash/keys' # Hash.symbolize_keys
require 'active_support/core_ext/numeric/time' # Numeric.hours

require 'active_record'

DB_FILE = 'tmp/test_db'
FileUtils.mkdir_p File.dirname(DB_FILE)
FileUtils.rm_f DB_FILE

ActiveRecord::Base.establish_connection :adapter => 'sqlite3', :database => DB_FILE

load('spec/schema.rb')

describe BackgroundWorker::Base do
  let(:cache) { double(write: nil, read: nil, reconnect: nil, store: nil) }
  let(:model_class) { Model = Class.new(ActiveRecord::Base) }
  let(:worker_class) {
    Class.new(BackgroundWorker::Base) do
      def perform(opts)
        Rails.cache.store(opts[:value])
      end
    end
  }

  before do
    stub_const 'Model', model_class
    stub_const 'Rails', double(cache: cache, env: 'production')
    BackgroundWorker.configure(backgrounded: false)
  end

  it 'should perform action and handle transactions/connections appropriately' do
    Model.transaction do
      worker_class.perform_later(value: 42)
    end
    expect(cache).to have_received(:store).with(42)
  end

  context '#queue_as' do
    it 'should value queue correctly' do
      worker_class.queue_as('low')
      expect(worker_class.queue).to be :low
    end
  end
end

describe BackgroundWorker::Base do
  describe 'callbacks' do
    let(:cache) { double(write: nil, read: nil, reconnect: nil, store: nil) }
    let(:model_class) { Model = Class.new(ActiveRecord::Base) }

    let(:worker_class) {
      Class.new(BackgroundWorker::Base) do
        def perform(opts)
          Rails.cache.store(opts[:value])
        end

        before_perform do
          Rails.cache.store('before_perform_action')
        end

        after_perform do
          Rails.cache.store('after_perform_action')
        end

        before_enqueue do
          Rails.cache.store('before_enqueue_action')
        end

        after_enqueue do
          Rails.cache.store('after_enqueue_action')
        end
      end
    }

    before do
      stub_const 'Model', model_class
      stub_const 'Rails', double(cache: cache, env: 'production')
      BackgroundWorker.configure(backgrounded: false)
    end

    it 'should call perform callbacks' do
      Model.transaction do
        worker_class.perform_later(value: 42)
      end
      expect(cache).to have_received(:store).with('before_enqueue_action')
      expect(cache).to have_received(:store).with('before_perform_action')
      expect(cache).to have_received(:store).with(42)
      expect(cache).to have_received(:store).with('after_perform_action')
      expect(cache).to have_received(:store).with('after_enqueue_action')
    end
  end
end
