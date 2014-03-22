require 'mixlib/shellout'

require 'spec_helper'

this_dir = File.dirname(__FILE__)
require File.expand_path('../../../libraries/pacemaker', this_dir)
require File.expand_path('../../fixtures/keystone_primitive', this_dir)

describe Pacemaker::CIBObject do

  before(:each) do
    Mixlib::ShellOut.any_instance.stub(:run_command)
  end

  let(:cib_object) { Chef::RSpec::Pacemaker::Config::KEYSTONE_PRIMITIVE.dup }

  #####################################################################
  # examples start here

  context "no CIB object" do
    before(:each) do
      expect_any_instance_of(Mixlib::ShellOut) \
        .to receive(:error!) \
        .and_raise(RuntimeError)
    end

    describe "#load_definition" do
      it "should return nil cluster config" do
        cib_object.load_definition
        expect(cib_object.definition).to eq(nil)
      end
    end

    describe "#exists?" do
      it "should return false" do
        cib_object.load_definition
        expect(cib_object.exists?).to be(false)
      end
    end
  end

  context "keystone primitive resource CIB object" do
    before(:each) do
      Mixlib::ShellOut.any_instance.stub(:error!)
      expect_any_instance_of(Mixlib::ShellOut) \
        .to receive(:stdout) \
        .and_return(cib_object.definition_string)
    end

    context "with definition loaded" do
      before(:each) do
        cib_object.load_definition
      end

      describe "#exists?" do
        it "should return true" do
          expect(cib_object.exists?).to be(true)
        end
      end

      describe "#load_definition" do
        it "should retrieve cluster config" do
          expect(cib_object.definition).to eq(cib_object.definition_string)
        end
      end

      describe "#type" do
        it "should return primitive" do
          expect(cib_object.type).to eq("primitive")
        end
      end
    end
  end

  context "CIB object with unregistered type" do
    before(:each) do
      Mixlib::ShellOut.any_instance.stub(:error!)
    end

    describe "::from_name" do
      it "should refuse to instantiate from any subclass" do
        expect_any_instance_of(Mixlib::ShellOut) \
          .to receive(:stdout) \
          .and_return("unregistered #{cib_object.name} <definition>")
        expect {
          Pacemaker::CIBObject.from_name(cib_object.name)
        }.to raise_error "No subclass of Pacemaker::CIBObject was registered with type 'unregistered'"
      end
    end
  end

  context "invalid CIB object definition" do
    before(:each) do
      Mixlib::ShellOut.any_instance.stub(:error!)
      expect_any_instance_of(Mixlib::ShellOut) \
        .to receive(:stdout) \
        .and_return("nonsense")
    end

    describe "#type" do
      it "should raise an error without a valid definition" do
        expect { cib_object.load_definition }.to \
          raise_error(RuntimeError, "Couldn't extract CIB object type from 'nonsense'")
      end
    end
  end
end
