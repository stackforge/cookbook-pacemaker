# Shared code used to test providers of CIB objects

require 'mixlib/shellout'

require File.expand_path('../../libraries/pacemaker/cib_object',
                         File.dirname(__FILE__))

module Chef::RSpec
  module Pacemaker
    module CIBObject
      # Return a Mixlib::ShellOut double which mimics successful
      # execution of a command, returning the given string on STDOUT.
      def shellout_double(string)
        shellout = double(Mixlib::ShellOut)
        shellout.stub(:environment).and_return({})
        shellout.stub(:run_command)
        shellout.stub(:error!)
        expect(shellout).to receive(:stdout).and_return(string)
        shellout
      end

      # This stubs Mixlib::ShellOut.new with a sequence of doubles
      # whose #stdout methods return a corresponding sequence of strings.
      # This allows us to simulate the output of a series of shell
      # commands being run via Mixlib::ShellOut.
      #
      # For example, "crm configure show" is executed by
      # #load_current_resource, and again later on for the :create
      # action, to see whether to create or modify.  So the first
      # double in the sequence would return an empty definition if we
      # wanted to test creation of a new CIB object, or an existing
      # definition if we wanted to test modification of an existing
      # one.  If the test needs subsequent doubles to return different
      # values then stdout_strings can have more than one element.
      def stub_shellout(*stdout_strings)
        doubles = stdout_strings.map { |string| shellout_double(string) }
        Mixlib::ShellOut.stub(:new).and_return(*doubles)
      end
    end
  end
end

shared_examples "a CIB object" do
  include Chef::RSpec::Pacemaker::CIBObject

  def expect_to_match_fixture(obj)
    expect(obj.is_a? pacemaker_object_class).to eq(true)
    fields.each do |field|
      method = field.to_sym
      expect(obj.send(method)).to eq(fixture.send(method))
    end
  end

  it "should be instantiated via Pacemaker::CIBObject.from_name" do
    stub_shellout(fixture.definition_string)
    obj = Pacemaker::CIBObject.from_name(fixture.name)
    expect_to_match_fixture(obj)
  end

  it "should instantiate by parsing a definition" do
    obj = Pacemaker::CIBObject.from_definition(fixture.definition_string)
    expect_to_match_fixture(obj)
  end

  it "should barf if the loaded definition's type is not colocation" do
    stub_shellout("clone foo blah blah")
    expect { fixture.load_definition }.to \
      raise_error(Pacemaker::CIBObject::TypeMismatch,
                  "Expected #{object_type} type but loaded definition was type clone")
  end
end

shared_examples "action on non-existent resource" do |action, cmd, expected_error|
  include Chef::RSpec::Pacemaker::CIBObject

  it "should not attempt to #{action.to_s} a non-existent resource" do
    stub_shellout("")

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
