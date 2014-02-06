# Shared code used to test providers of CIB objects

require 'mixlib/shellout'

require File.expand_path('../../libraries/pacemaker/cib_object',
                         File.dirname(__FILE__))

shared_examples "a CIB object" do
  def expect_to_match_fixture(obj)
    expect(obj.is_a? pacemaker_object_class).to eq(true)
    fields.each do |field|
      method = field.to_sym
      expect(obj.send(method)).to eq(fixture.send(method))
    end
  end

  it "should be instantiated via Pacemaker::CIBObject.from_name" do
    Mixlib::ShellOut.any_instance.stub(:error!)
    expect_any_instance_of(Mixlib::ShellOut) \
      .to receive(:stdout) \
      .and_return(fixture.definition_string)

    obj = Pacemaker::CIBObject.from_name(fixture.name)
    expect_to_match_fixture(obj)
  end

  it "should instantiate by parsing a definition" do
    obj = Pacemaker::CIBObject.from_definition(fixture.definition_string)
    expect_to_match_fixture(obj)
  end

  it "should barf if the loaded definition's type is not colocation" do
    Mixlib::ShellOut.any_instance.stub(:error!)
    expect_any_instance_of(Mixlib::ShellOut) \
      .to receive(:stdout) \
      .and_return("clone foo blah blah")
    expect { fixture.load_definition }.to \
      raise_error(Pacemaker::CIBObject::TypeMismatch,
                  "Expected #{object_type} type but loaded definition was type clone")
  end
end

shared_examples "action on non-existent resource" do |action, cmd, expected_error|
  it "should not attempt to #{action.to_s} a non-existent resource" do
    expect_definition("")

    if expected_error
      expect { provider.run_action action }.to \
        raise_error(RuntimeError, expected_error)
    else
      provider.run_action action
    end

    expect(@chef_run).not_to run_execute(cmd)
    expect(@resource).not_to be_updated
  end
end

module Chef::RSpec
  module Pacemaker
    module CIBObject
      # "crm configure show" is executed by load_current_resource, and
      # again later on for the :create action, to see whether to create or
      # modify.
      def expect_definition(definition)
        Mixlib::ShellOut.any_instance.stub(:run_command)
        Mixlib::ShellOut.any_instance.stub(:error!)
        expect_any_instance_of(Mixlib::ShellOut) \
          .to receive(:stdout) \
          .and_return(definition)
      end

      def expect_exists(exists)
        expect_any_instance_of(cib_object_class) \
          .to receive(:exists?) \
          .and_return(exists)
      end
    end
  end
end
