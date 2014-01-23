require 'spec_helper'
require_relative File.join(%w(.. .. libraries cib_objects))
require_relative File.join(%w(.. helpers keystone_config))

describe Chef::Libraries::Pacemaker::CIBObjects do
  include Chef::Libraries::Pacemaker::CIBObjects

  shared_context "shellout stubs" do
    before(:each) do
      Mixlib::ShellOut.any_instance.stub(:run_command)
    end
  end

  shared_context "keystone config" do
    let(:ra) { Chef::RSpec::Pacemaker::Config::RA }
  end

  shared_context "keystone primitive" do
    include_context "shellout stubs"
    include_context "keystone config"

    before(:each) do
      Mixlib::ShellOut.any_instance.stub(:error!)
      expect_any_instance_of(Mixlib::ShellOut) \
        .to receive(:stdout) \
        .and_return(ra[:config])
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
      expect(get_cib_object_definition("keystone")).to eq(ra[:config])
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
      expect(cib_object_type(ra[:config])).to eq("primitive")
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

  describe "#resource_params_string" do
    it "should return empty string with nil params" do
      expect(resource_params_string(nil)).to eq("")
    end

    it "should return empty string with empty params" do
      expect(resource_params_string({})).to eq("")
    end

    it "should return a resource params string" do
      params = {
        "foo" => "bar",
        "baz" => "qux",
      }
      expect(resource_params_string(params)).to eq(%' params baz="qux" foo="bar"')
    end
  end

  describe "#resource_meta_string" do
    it "should return empty string with nil meta" do
      expect(resource_meta_string(nil)).to eq("")
    end

    it "should return empty string with empty meta" do
      expect(resource_meta_string({})).to eq("")
    end

    it "should return a resource meta string" do
      meta = {
        "foo" => "bar",
        "baz" => "qux",
      }
      expect(resource_meta_string(meta)).to eq(%' meta baz="qux" foo="bar"')
    end
  end

  describe "#resource_op_string" do
    it "should return empty string with nil op" do
      expect(resource_op_string(nil)).to eq("")
    end

    it "should return empty string with empty op" do
      expect(resource_op_string({})).to eq("")
    end

    it "should return a resource op string" do
      op = {
        "monitor" => {
          "foo" => "bar",
          "baz" => "qux",
        }
      }
      expect(resource_op_string(op)).to eq(%' op monitor baz="qux" foo="bar"')
    end
  end

  describe "#extract_hash" do
    include_context "keystone config"

    it "should extract a hash from config" do
      expect(extract_hash("keystone", ra[:config], "params")).to eq(Hash[ra[:params]])
    end

  end

end
