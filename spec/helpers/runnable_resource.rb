# Shared code used to test providers of runnable Chef resources
# representing Pacemaker CIB objects.  For example the provider
# for primitives is runnable (since primitives can be started
# and stopped) but constraints cannot.

this_dir = File.dirname(__FILE__)
require File.expand_path('provider', this_dir)
require File.expand_path('shellout', this_dir)

shared_examples "a runnable resource" do |fixture|
  def expect_running(running)
    expect_any_instance_of(cib_object_class) \
      .to receive(:running?) \
      .and_return(running)
  end

  include Chef::RSpec::Mixlib::ShellOut

  describe ":delete action" do
    it_should_behave_like "action on non-existent resource", \
      :delete, "crm configure delete #{fixture.name}", nil

    it "should not delete a running resource" do
      stub_shellout(fixture.definition_string)
      expect_running(true)

      expected_error = "Cannot delete running #{fixture}"
      expect { provider.run_action :delete }.to \
        raise_error(RuntimeError, expected_error)

      cmd = "crm configure delete '#{fixture.name}'"
      expect(@chef_run).not_to run_execute(cmd)
      expect(@resource).not_to be_updated
    end

    it "should delete a non-running resource" do
      stub_shellout(fixture.definition_string)
      expect_running(false)

      provider.run_action :delete

      cmd = "crm configure delete '#{fixture.name}'"
      expect(@chef_run).to run_execute(cmd)
      expect(@resource).to be_updated
    end
  end

  describe ":start action" do
    it_should_behave_like "action on non-existent resource", \
      :start,
      "crm resource start #{fixture.name}", \
      "Cannot start non-existent #{fixture}"

    it "should do nothing to a started resource" do
      stub_shellout(fixture.definition_string)
      expect_running(true)

      provider.run_action :start

      cmd = "crm resource start #{fixture.name}"
      expect(@chef_run).not_to run_execute(cmd)
      expect(@resource).not_to be_updated
    end

    it "should start a stopped resource" do
      config = fixture.definition_string.sub("Started", "Stopped")
      stub_shellout(config)
      expect_running(false)

      provider.run_action :start

      cmd = "crm resource start '#{fixture.name}'"
      expect(@chef_run).to run_execute(cmd)
      expect(@resource).to be_updated
    end
  end

  describe ":stop action" do
    it_should_behave_like "action on non-existent resource", \
      :stop,
      "crm resource stop #{fixture.name}", \
      "Cannot stop non-existent #{fixture}"

    it "should do nothing to a stopped resource" do
      stub_shellout(fixture.definition_string)
      expect_running(false)

      provider.run_action :stop

      cmd = "crm resource start #{fixture.name}"
      expect(@chef_run).not_to run_execute(cmd)
      expect(@resource).not_to be_updated
    end

    it "should stop a started resource" do
      stub_shellout(fixture.definition_string)
      expect_running(true)

      provider.run_action :stop

      cmd = "crm resource stop '#{fixture.name}'"
      expect(@chef_run).to run_execute(cmd)
      expect(@resource).to be_updated
    end
  end

end
