require 'chef/application'
require_relative File.join(%w(.. spec_helper))
require_relative File.join(%w(.. fixtures keystone_primitive))

describe "Chef::Provider::PacemakerPrimitive" do
  # for use inside examples:
  let(:rsc) { Chef::RSpec::Pacemaker::Config::KEYSTONE_PRIMITIVE }
  # for use outside examples (e.g. when invoking shared_examples)
  rsc = Chef::RSpec::Pacemaker::Config::KEYSTONE_PRIMITIVE

  before(:each) do
    runner_opts = {
      :step_into => ['pacemaker_primitive']
    }
    @chef_run = ::ChefSpec::Runner.new(runner_opts)
    @chef_run.converge "pacemaker::default"
    @node = @chef_run.node
    @run_context = @chef_run.run_context

    @resource = Chef::Resource::PacemakerPrimitive.new(rsc.name, @run_context)
    @resource.agent  rsc.agent
    @resource.params Hash[rsc.params]
    @resource.meta   Hash[rsc.meta]
    @resource.op     Hash[rsc.op]
  end

  let (:provider) { Chef::Provider::PacemakerPrimitive.new(@resource, @run_context) }

  # "crm configure show" is executed by load_current_resource, and
  # again later on for the :create action, to see whether to create or
  # modify.
  def expect_definition(definition)
    Mixlib::ShellOut.any_instance.stub(:run_command)
    Mixlib::ShellOut.any_instance.stub(:error!)
    expect_any_instance_of(Mixlib::ShellOut) \
      .to receive(:stdout) \
      .and_return(definition)
  end

  def expect_exists(exists)
    expect_any_instance_of(Pacemaker::Resource::Primitive) \
      .to receive(:exists?) \
      .and_return(exists)
  end

  def expect_running(running)
    expect_any_instance_of(Pacemaker::Resource::Primitive) \
      .to receive(:running?) \
      .and_return(running)
  end

  describe ":create action" do
    it "should modify the primitive if it already exists" do
      new_params = Hash[rsc.params].merge("os_password" => "newpasswd")
      new_params.delete("os_tenant_name")
      @resource.params new_params
      @resource.meta Hash[rsc.meta].merge("target-role" => "Stopped")

      expect_definition(rsc.definition_string)

      configure_cmd_prefix = "crm_resource --resource #{rsc.name}"
      expected_configure_cmd_args = [
        %'--set-parameter "os_password" --parameter-value "newpasswd"',
        %'--delete-parameter "os_tenant_name"',
        %'--set-parameter "target-role" --parameter-value "Stopped" --meta',
      ]

      provider.run_action :create

      expected_configure_cmd_args.each do |args|
        cmd = configure_cmd_prefix + " " + args
        expect(@chef_run).to run_execute(cmd)
      end
      expect(@resource).to be_updated
    end

    it "should create a primitive if it doesn't already exist" do
      expect_definition("")
      # Later, the :create action calls Pacemaker::Resource::Primitive#exists? to check
      # that creation succeeded.
      expect_exists(true)

      provider.run_action :create

      expect(@chef_run).to run_execute(rsc.crm_configure_command)
      expect(@resource).to be_updated
    end

    it "should barf if the primitive is already defined with the wrong agent" do
      existing_agent = "ocf:openstack:something-else"
      definition = rsc.definition_string.sub(rsc.agent, existing_agent)
      expect_definition(definition)

      expected_error = \
        "Existing resource primitive '#{rsc.name}' has agent '#{existing_agent}' " \
        "but recipe wanted '#{@resource.agent}'"
      expect { provider.run_action :create }.to \
        raise_error(RuntimeError, expected_error)

      expect(@resource).not_to be_updated
    end
  end

  shared_examples "action on non-existent resource" do |action, cmd, expected_error|
    it "should not attempt to #{action.to_s} a non-existent resource" do
      expect_definition("")

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

  describe ":delete action" do
    it_should_behave_like "action on non-existent resource", \
      :delete, "crm configure delete #{rsc.name}", nil

    it "should not delete a running resource" do
      expect_definition(rsc.definition_string)
      expect_running(true)

      expected_error = "Cannot delete running resource primitive #{rsc.name}"
      expect { provider.run_action :delete }.to \
        raise_error(RuntimeError, expected_error)

      cmd = "crm configure delete '#{rsc.name}'"
      expect(@chef_run).not_to run_execute(cmd)
      expect(@resource).not_to be_updated
    end

    it "should delete a non-running resource" do
      expect_definition(rsc.definition_string)
      expect_running(false)

      provider.run_action :delete

      cmd = "crm configure delete '#{rsc.name}'"
      expect(@chef_run).to run_execute(cmd)
      expect(@resource).to be_updated
    end
  end

  describe ":start action" do
    it_should_behave_like "action on non-existent resource", \
      :start,
      "crm resource start #{rsc.name}", \
      "Cannot start non-existent resource primitive '#{rsc.name}'"

    it "should do nothing to a started resource" do
      expect_definition(rsc.definition_string)
      expect_running(true)

      provider.run_action :start

      cmd = "crm resource start #{rsc.name}"
      expect(@chef_run).not_to run_execute(cmd)
      expect(@resource).not_to be_updated
    end

    it "should start a stopped resource" do
      config = rsc.definition_string.sub("Started", "Stopped")
      expect_definition(config)
      expect_running(false)

      provider.run_action :start

      cmd = "crm resource start '#{rsc.name}'"
      expect(@chef_run).to run_execute(cmd)
      expect(@resource).to be_updated
    end
  end

  describe ":stop action" do
    it_should_behave_like "action on non-existent resource", \
      :stop,
      "crm resource stop #{rsc.name}", \
      "Cannot stop non-existent resource primitive '#{rsc.name}'"

    it "should do nothing to a stopped resource" do
      expect_definition(rsc.definition_string)
      expect_running(false)

      provider.run_action :stop

      cmd = "crm resource start #{rsc.name}"
      expect(@chef_run).not_to run_execute(cmd)
      expect(@resource).not_to be_updated
    end

    it "should stop a started resource" do
      expect_definition(rsc.definition_string)
      expect_running(true)

      provider.run_action :stop

      cmd = "crm resource stop '#{rsc.name}'"
      expect(@chef_run).to run_execute(cmd)
      expect(@resource).to be_updated
    end
  end

end
