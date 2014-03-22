# Shared code used to test providers of CIB objects

this_dir = File.dirname(__FILE__)
require File.expand_path('../helpers/cib_object', this_dir)

shared_context "a Pacemaker LWRP" do
  before(:each) do
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
