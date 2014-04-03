# Shared code used to test providers of CIB objects

this_dir = File.dirname(__FILE__)
require File.expand_path('shellout',   this_dir)
require File.expand_path('cib_object', this_dir)

shared_context "a Pacemaker LWRP" do
  before(:each) do
    stub_command("crm configure show smtp-notifications")
    stub_command("crm configure show cl-smtp-notifications")

    runner_opts = {
      :step_into => [lwrp_name]
    }
    @chef_run = ::ChefSpec::Runner.new(runner_opts)
    @chef_run.converge "pacemaker::default"
    @node = @chef_run.node
    @run_context = @chef_run.run_context

    camelized_subclass_name = "Pacemaker" + lwrp_name.capitalize
    @resource_class = ::Chef::Resource.const_get(camelized_subclass_name)
    @provider_class = ::Chef::Provider.const_get(camelized_subclass_name)

    @resource = @resource_class.new(fixture.name, @run_context)
  end

  let (:provider) { @provider_class.new(@resource, @run_context) }
end

module Chef::RSpec
  module Pacemaker
    module CIBObject
      include Chef::RSpec::Mixlib::ShellOut

      def test_modify(expected_cmds)
        yield

        stub_shellout(fixture.definition_string)

        provider.run_action :create

        expected_cmds.each do |cmd|
          expect(@chef_run).to run_execute(cmd)
        end
        expect(@resource).to be_updated
      end
    end
  end
end

shared_examples "action on non-existent resource" do |action, cmd, expected_error|
  include Chef::RSpec::Mixlib::ShellOut

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

shared_examples "all Pacemaker LWRPs" do |fixture|
  describe ":delete action" do
    it_should_behave_like "action on non-existent resource", \
      :delete, "crm configure delete #{fixture.name}", nil
  end
end
