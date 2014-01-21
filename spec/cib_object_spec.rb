require 'spec_helper'
require_relative File.join(%w(.. libraries cib_objects))
require_relative 'keystone_config'

describe Chef::Libraries::Pacemaker::CIBObjects do
  include Chef::Libraries::Pacemaker::CIBObjects

  shared_context "shellout stubs" do
    before(:each) do
      Mixlib::ShellOut.any_instance.stub(:run_command)
    end
  end


  shared_context "keystone primitive" do
    include_context "shellout stubs"
    include_context "keystone config"

    before(:each) do
      Mixlib::ShellOut.any_instance.stub(:error!)
      expect_any_instance_of(Mixlib::ShellOut) \
        .to receive(:stdout) \
        .and_return(@config)
    end
  end

  shared_context "no keystone primitive" do
    include_context "shellout stubs"
    before(:each) do
      expect_any_instance_of(Mixlib::ShellOut) \
        .to receive(:error!) \
        .and_raise(RuntimeError)
    end
  end

  describe "#get_cib_object_definition" do
    include_context "keystone primitive"

    it "should retrieve cluster config" do
      expect(get_cib_object_definition("keystone")).to eq(@config)
    end
  end

  describe "#get_cib_object_definition" do
    include_context "no keystone primitive"

    it "should return nil cluster config" do
      expect(get_cib_object_definition("keystone")).to eq(nil)
    end
  end

  describe "#cib_object_exists?" do
    include_context "keystone primitive"

    it "should return true" do
      expect(cib_object_exists?("keystone")).to be(true)
    end
  end

  describe "#cib_object_exists?" do
    include_context "no keystone primitive"

    it "should return false" do
      expect(cib_object_exists?("keystone")).to be(false)
    end
  end

  describe "#cib_object_type" do
    include_context "keystone config"

    it "should return primitive" do
      expect(cib_object_type(@config)).to eq("primitive")
    end

    it "should raise an error without valid config" do
      expect { cib_object_type("nonsense") }.to raise_error
    end
  end

  describe "#pacemaker_resource_running?" do
    before(:each) do
      @cmd = double(Mixlib::ShellOut)
      expect(self).to receive(:shell_out!) \
        .with(*%w(crm resource status keystone)).ordered \
        .and_return(@cmd)
    end

    it "should return true" do
      expect(@cmd).to receive(:stdout).at_least(:once).and_return("resource keystone is running")
      expect(pacemaker_resource_running?("keystone")).to be(true)
    end

    it "should return false" do
      expect(@cmd).to receive(:stdout).at_least(:once).and_return("resource keystone is not running")
      expect(pacemaker_resource_running?("keystone")).to be(false)
    end
  end

  describe "#extract_hash" do
    include_context "keystone config"

    it "should extract a hash from config" do
      expect(extract_hash("keystone", @config, "params")).to eq(@params)
    end

  end

end
