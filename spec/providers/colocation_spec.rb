require 'chef/application'
require File.join(File.dirname(__FILE__), %w(.. spec_helper))
require File.join(File.dirname(__FILE__), %w(.. helpers common))
require File.join(File.dirname(__FILE__), %w(.. fixtures colocation_constraint))

describe "Chef::Provider::PacemakerColocation" do
  # for use inside examples:
  let(:colo) { Chef::RSpec::Pacemaker::Config::COLOCATION_CONSTRAINT.dup }
  # for use outside examples (e.g. when invoking shared_examples)
  colo = Chef::RSpec::Pacemaker::Config::COLOCATION_CONSTRAINT.dup

  before(:each) do
    runner_opts = {
      :step_into => ['pacemaker_colocation']
    }
    @chef_run = ::ChefSpec::Runner.new(runner_opts)
    @chef_run.converge "pacemaker::default"
    @node = @chef_run.node
    @run_context = @chef_run.run_context

    @resource = Chef::Resource::PacemakerColocation.new(colo.name, @run_context)
    @resource.score     colo.score
    @resource.resources colo.resources.dup
  end

  let (:provider) { Chef::Provider::PacemakerColocation.new(@resource, @run_context) }

  def cib_object_class
    Pacemaker::Constraint::Colocation
  end

  include Chef::RSpec::Pacemaker::Common

  describe ":create action" do
    def test_modify(expected_cmds)
      yield

      expect_definition(colo.definition_string)

      provider.run_action :create

      expected_cmds.each do |cmd|
        expect(@chef_run).to run_execute(cmd)
      end
      expect(@resource).to be_updated
    end

    it "should modify the constraint if it has a different score" do
      echo_string = colo.quoted_definition_string.gsub('inf', '100')
      expected_configure_cmd_args = [
        "echo #{echo_string} | crm configure load update -"
      ]
      test_modify(expected_configure_cmd_args) do
        @resource.score '100'
      end
    end

    it "should modify the constraint if it has a resource added" do
      new_resource = 'bar:Stopped'
      expected = colo.dup
      expected.resources = expected.resources.dup + [new_resource]
      echo_string = expected.quoted_definition_string
      expected_configure_cmd_args = [
        "echo #{echo_string} | crm configure load update -"
      ]
      test_modify(expected_configure_cmd_args) do
        @resource.resources expected.resources
      end
    end

    it "should modify the constraint if it has a different resource" do
      new_resources = ['bar:Started']
      colo.resources = new_resources
      echo_string = colo.quoted_definition_string
      expected_configure_cmd_args = [
        "echo #{echo_string} | crm configure load update -"
      ]
      test_modify(expected_configure_cmd_args) do
        @resource.resources new_resources
      end
    end

  end

  describe ":delete action" do
    it_should_behave_like "action on non-existent resource", \
      :delete, "crm configure delete #{colo.name}", nil
  end

end
