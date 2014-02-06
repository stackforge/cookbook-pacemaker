require 'mixlib/shellout'

# Shared code used to test providers of CIB objects

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
