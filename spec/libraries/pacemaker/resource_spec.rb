require 'mixlib/shellout'

require 'spec_helper'

this_dir = File.dirname(__FILE__)
require File.expand_path('../../../libraries/pacemaker/resource', this_dir)
require File.expand_path('../../fixtures/keystone_primitive', this_dir)

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

  describe "::extract_hash" do
    let(:fixture) { Chef::RSpec::Pacemaker::Config::KEYSTONE_PRIMITIVE.dup }

    it "should extract a params hash from config" do
      expect(fixture.class.extract_hash(fixture.definition_string, "params")).to \
        eq(Hash[fixture.params])
    end

    it "should extract an op start hash from config" do
      expect(fixture.class.extract_hash(fixture.definition_string, 'op start')).to \
        eq(Hash[fixture.op]['start'])
    end

    it "should extract an op monitor hash from config" do
      expect(fixture.class.extract_hash(fixture.definition_string, 'op monitor')).to \
        eq(Hash[fixture.op]['monitor'])
    end
  end
end
