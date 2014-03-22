require File.expand_path('../spec_helper', File.dirname(__FILE__))
require File.expand_path('../helpers/cib_object', File.dirname(__FILE__))
require File.expand_path('../helpers/runnable_resource', File.dirname(__FILE__))
require File.expand_path('../fixtures/ms_resource', File.dirname(__FILE__))

describe "Chef::Provider::PacemakerMs" do
  # for use inside examples:
  let(:fixture) { Chef::RSpec::Pacemaker::Config::MS_RESOURCE.dup }
  # for use outside examples (e.g. when invoking shared_examples)
  fixture = Chef::RSpec::Pacemaker::Config::MS_RESOURCE.dup

  before(:each) do
    runner_opts = {
      :step_into => ['pacemaker_ms']
    }
    @chef_run = ::ChefSpec::Runner.new(runner_opts)
    @chef_run.converge "pacemaker::default"
    @node = @chef_run.node
    @run_context = @chef_run.run_context

    @resource = Chef::Resource::PacemakerMs.new(fixture.name, @run_context)
    @resource.rsc  fixture.rsc.dup
    @resource.meta Hash[fixture.meta.dup]
  end

  let (:provider) { Chef::Provider::PacemakerMs.new(@resource, @run_context) }

  def cib_object_class
    Pacemaker::Resource::MasterSlave
  end

  include Chef::RSpec::Pacemaker::CIBObject

  describe ":create action" do
    def test_modify(expected_cmds)
      yield

      stub_shellout(fixture.definition_string)

      provider.run_action :create

      expected_cmds.each do |cmd|
        expect(@chef_run).to run_execute(cmd)
      end
      expect(@resource).to be_updated
    end

    it "should modify the resource if it's changed" do
      expected = fixture.dup
      expected.rsc = 'primitive2'
      expected_configure_cmd_args = [expected.reconfigure_command]
      test_modify(expected_configure_cmd_args) do
        @resource.rsc expected.rsc
      end
    end

  end

  it_should_behave_like "a runnable resource", fixture

end
