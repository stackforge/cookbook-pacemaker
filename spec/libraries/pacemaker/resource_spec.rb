require 'spec_helper'
require_relative File.join(%w(.. .. .. libraries pacemaker resource))

describe Pacemaker::Resource do
  describe "#running?" do
    let(:rsc) { Pacemaker::Resource.new('keystone') }

    before(:each) do
      @cmd = double(Mixlib::ShellOut)
      expect(rsc).to receive(:shell_out!) \
        .with(*%w(crm resource status keystone)) \
        .and_return(@cmd)
    end

    it "should return true" do
      expect(@cmd).to receive(:stdout).at_least(:once) \
        .and_return("resource #{rsc.name} is running on: d52-54-00-e5-6b-a0")
      expect(rsc.running?).to be(true)
    end

    it "should return false" do
      expect(@cmd).to receive(:stdout).at_least(:once) \
        .and_return("resource #{rsc.name} is NOT running")
      expect(rsc.running?).to be(false)
    end
  end
end
