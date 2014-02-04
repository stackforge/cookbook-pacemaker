require 'mixlib/shellout'

module Chef::RSpec
  module Pacemaker
    module Common
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
