# Shared code used to test providers of non-runnable Chef resources
# representing Pacemaker CIB objects.  For example the provider for
# primitives is runnable (since primitives can be started and stopped)
# but constraints cannot.

this_dir = File.dirname(__FILE__)
require File.expand_path('provider', this_dir)
require File.expand_path('shellout', this_dir)

shared_examples "a non-runnable resource" do |fixture|
  include Chef::RSpec::Mixlib::ShellOut

  it_should_behave_like "all Pacemaker LWRPs", fixture

  describe ":delete action" do
    it "should delete a resource" do
      stub_shellout(fixture.definition_string)

      provider.run_action :delete

      cmd = "crm configure delete '#{fixture.name}'"
      expect(@chef_run).to run_execute(cmd)
      expect(@resource).to be_updated
    end
  end
end
