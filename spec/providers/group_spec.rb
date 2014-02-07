require 'chef/application'
require File.expand_path('../spec_helper', File.dirname(__FILE__))
require File.expand_path('../helpers/cib_object', File.dirname(__FILE__))
require File.expand_path('../helpers/runnable_resource', File.dirname(__FILE__))
require File.expand_path('../fixtures/resource_group', File.dirname(__FILE__))

describe "Chef::Provider::PacemakerGroup" do
  # for use inside examples:
  let(:fixture) { Chef::RSpec::Pacemaker::Config::RESOURCE_GROUP.dup }
  # for use outside examples (e.g. when invoking shared_examples)
  fixture = Chef::RSpec::Pacemaker::Config::RESOURCE_GROUP.dup

  before(:each) do
    runner_opts = {
      :step_into => ['pacemaker_group']
    }
    @chef_run = ::ChefSpec::Runner.new(runner_opts)
    @chef_run.converge "pacemaker::default"
    @node = @chef_run.node
    @run_context = @chef_run.run_context

    @resource = Chef::Resource::PacemakerGroup.new(fixture.name, @run_context)
    @resource.members fixture.members.dup
    @resource.meta    Hash[fixture.meta.dup]
  end

  let (:provider) { Chef::Provider::PacemakerGroup.new(@resource, @run_context) }

  def cib_object_class
    Pacemaker::Resource::Group
  end

  include Chef::RSpec::Pacemaker::CIBObject

  describe ":create action" do
    def test_modify(expected_cmds)
      yield

      expect_definitions(fixture.definition_string)

      provider.run_action :create

      expected_cmds.each do |cmd|
        expect(@chef_run).to run_execute(cmd)
      end
      expect(@resource).to be_updated
    end

    it "should modify the group if it has a member resource added" do
      expected = fixture.dup
      expected.members = expected.members.dup + %w(resource3)
      expected_configure_cmd_args = [expected.reconfigure_command]
      test_modify(expected_configure_cmd_args) do
        @resource.members expected.members
      end
    end

    it "should modify the group if it has different member resources" do
      fixture.members = %w(resource1 resource3)
      expected_configure_cmd_args = [fixture.reconfigure_command]
      test_modify(expected_configure_cmd_args) do
        @resource.members fixture.members
      end
    end

  end

  it_should_behave_like "a runnable resource", fixture

end
