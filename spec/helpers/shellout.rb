require 'mixlib/shellout'

module Chef::RSpec
  module Mixlib
    module ShellOut
      # Return a Mixlib::ShellOut double which mimics successful
      # execution of a command, returning the given string on STDOUT.
      def succeeding_shellout_double(string)
        shellout = double(Mixlib::ShellOut)
        shellout.stub(:environment).and_return({})
        shellout.stub(:run_command)
        shellout.stub(:error!)
        expect(shellout).to receive(:stdout).and_return(string)
        shellout
      end

      # Return a Mixlib::ShellOut double which mimics failed
      # execution of a command, raising an exception when #error! is
      # called.  We expect #error! to be called, because if it isn't,
      # that probably indicates the code isn't robust enough.  This
      # may need to be relaxed in the future.
      def failing_shellout_double(stdout='', stderr='', exitstatus=1)
        shellout = double(Mixlib::ShellOut)
        shellout.stub(:environment).and_return({})
        shellout.stub(:run_command)
        shellout.stub(:stdout).and_return(stdout)
        shellout.stub(:stderr).and_return(stderr)
        shellout.stub(:exitstatus).and_return(exitstatus)
        exception = ::Mixlib::ShellOut::ShellCommandFailed.new(
          "Expected process to exit with 0, " +
          "but received '#{exitstatus}'"
        )
        expect(shellout).to receive(:error!).and_raise(exception)
        shellout
      end

      # This stubs Mixlib::ShellOut.new with a sequence of doubles
      # with a corresponding sequence of behaviours.  This allows us
      # to simulate the output of a series of shell commands being run
      # via Mixlib::ShellOut.  Each double either mimics a successful
      # command execution whose #stdout method returns the given
      # string, or a failed execution with the given exit code and
      # STDOUT/STDERR.
      #
      # results is an Array describing the sequence of behaviours;
      # each element is either a string mimicking STDOUT from
      # successful command execution, or a [stdout, stderr, exitcode]
      # status mimicking command execution failure.
      #
      # For example, "crm configure show" is executed by
      # #load_current_resource, and again later on for the :create
      # action, to see whether to create or modify.  So the first
      # double in the sequence would return an empty definition if we
      # wanted to test creation of a new CIB object, or an existing
      # definition if we wanted to test modification of an existing
      # one.  If the test needs subsequent doubles to return different
      # values then stdout_strings can have more than one element.
      def stub_shellout(*results)
        doubles = results.map { |result|
          result.is_a?(String) ?
              succeeding_shellout_double(result)
            : failing_shellout_double(*result)
        }
        ::Mixlib::ShellOut.stub(:new).and_return(*doubles)
      end
    end
  end
end
