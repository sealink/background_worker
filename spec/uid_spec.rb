require 'spec_helper'

describe BackgroundWorker::Uid do
  let(:class_name) { 'CopyWorker' }
  let(:method) { 'make_copy' }
  let(:uid_object) { BackgroundWorker::Uid.new(class_name, method) }

  context '#generate' do
    subject(:uid) { uid_object.generate }
    it { is_expected.to match(/copy_worker:make_copy:[0-9a-f]{16}/) }

    context '#parse' do
      subject { BackgroundWorker::Uid.parse(uid) }
      specify { expect(subject.class_name).to eq class_name }
      specify { expect(subject.method).to eq method }
    end
  end
end
