require 'spec_helper'

describe BackgroundWorker::Uid do
  let(:class_name) { 'CopyWorker' }
  let(:uid_object) { BackgroundWorker::Uid.new(class_name) }

  context '#generate' do
    subject(:uid) { uid_object.generate }
    it { is_expected.to match(/copy_worker:[0-9a-f]{16}/) }
  end
end
