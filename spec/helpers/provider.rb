# Shared code used to test providers of CIB objects

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
