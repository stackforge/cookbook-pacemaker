require 'chef/application'
require File.expand_path('../spec_helper', File.dirname(__FILE__))
require File.expand_path('../helpers/cib_object', File.dirname(__FILE__))
require File.expand_path('../helpers/runnable_resource', File.dirname(__FILE__))
require File.expand_path('../fixtures/keystone_primitive', File.dirname(__FILE__))

describe "Chef::Provider::PacemakerPrimitive" do
  # for use inside examples:
  let(:fixture) { Chef::RSpec::Pacemaker::Config::KEYSTONE_PRIMITIVE }
  # for use outside examples (e.g. when invoking shared_examples)
  fixture = Chef::RSpec::Pacemaker::Config::KEYSTONE_PRIMITIVE

  before(:each) do
    runner_opts = {
      :step_into => ['pacemaker_primitive']
    }
    @chef_run = ::ChefSpec::Runner.new(runner_opts)
    @chef_run.converge "pacemaker::default"
    @node = @chef_run.node
    @run_context = @chef_run.run_context

    @resource = Chef::Resource::PacemakerPrimitive.new(fixture.name, @run_context)
    @resource.agent  fixture.agent
    @resource.params Hash[fixture.params]
    @resource.meta   Hash[fixture.meta]
    @resource.op     Hash[fixture.op]
  end

  let (:provider) { Chef::Provider::PacemakerPrimitive.new(@resource, @run_context) }

  def cib_object_class
    Pacemaker::Resource::Primitive
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

    it "should modify the primitive if it has different params" do
      expected_configure_cmd_args = [
        %'--set-parameter "os_password" --parameter-value "newpasswd"',
        %'--delete-parameter "os_tenant_name"',
      ].map { |args| "crm_resource --resource #{fixture.name} #{args}" }
      test_modify(expected_configure_cmd_args) do
        new_params = Hash[fixture.params].merge("os_password" => "newpasswd")
        new_params.delete("os_tenant_name")
        @resource.params new_params
        @resource.meta Hash[fixture.meta].merge("target-role" => "Stopped")
      end
    end

    it "should modify the primitive if it has different meta" do
      expected_configure_cmd_args = [
        %'--set-parameter "target-role" --parameter-value "Stopped" --meta',
      ].map { |args| "crm_resource --resource #{fixture.name} #{args}" }
      test_modify(expected_configure_cmd_args) do
        @resource.params Hash[fixture.params]
        @resource.meta Hash[fixture.meta].merge("target-role" => "Stopped")
      end
    end

    it "should modify the primitive if it has different params and meta" do
      expected_configure_cmd_args = [
        %'--set-parameter "os_password" --parameter-value "newpasswd"',
        %'--delete-parameter "os_tenant_name"',
        %'--set-parameter "target-role" --parameter-value "Stopped" --meta',
      ].map { |args| "crm_resource --resource #{fixture.name} #{args}" }
      test_modify(expected_configure_cmd_args) do
        new_params = Hash[fixture.params].merge("os_password" => "newpasswd")
        new_params.delete("os_tenant_name")
        @resource.params new_params
        @resource.meta Hash[fixture.meta].merge("target-role" => "Stopped")
      end
    end

    it "should modify the primitive if it has different op values" do
      expected_configure_cmd_args = [
        fixture.reconfigure_command.gsub('60', '120')
      ]
      test_modify(expected_configure_cmd_args) do
        new_op = Hash[fixture.op]
        # Ensure we're not modifying our expectation as well as the input
        new_op['monitor'] = new_op['monitor'].dup
        new_op['monitor']['timeout'] = '120'
        @resource.op new_op
      end
    end

    it "should create a primitive if it doesn't already exist" do
      # The first time, Mixlib::ShellOut needs to return an empty definition.
      # Then the resource gets created so the second time it needs to return
      # the definition used for creation.
      expect_definitions("", fixture.definition_string)

      provider.run_action :create

      expect(@chef_run).to run_execute(fixture.crm_configure_command)
      expect(@resource).to be_updated
    end

    it "should barf if the primitive is already defined with the wrong agent" do
      existing_agent = "ocf:openstack:something-else"
      definition = fixture.definition_string.sub(fixture.agent, existing_agent)
      expect_definitions(definition)

      expected_error = \
        "Existing #{fixture} has agent '#{existing_agent}' " \
        "but recipe wanted '#{@resource.agent}'"
      expect { provider.run_action :create }.to \
        raise_error(RuntimeError, expected_error)

      expect(@resource).not_to be_updated
    end
  end

  it_should_behave_like "a runnable resource", fixture

end
