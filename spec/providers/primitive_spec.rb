require 'chef/application'
require_relative File.join(%w(.. spec_helper))
require_relative File.join(%w(.. helpers keystone_config))

describe "Chef::Provider::PacemakerPrimitive" do
  before do
    runner_opts = {
      :step_into => ['pacemaker_primitive']
    }
    @chef_run = ::ChefSpec::Runner.new(runner_opts) #::OPENSUSE_OPTS
    @chef_run.converge "pacemaker::default"
    @node = @chef_run.node
    @run_context = @chef_run.run_context

    @resource = Chef::Resource::PacemakerPrimitive.new("keystone", @run_context)

    ra = Chef::RSpec::Pacemaker::Config::RA
    @resource.agent  ra[:agent]
    @resource.params Hash[ra[:params]]
    @resource.meta   Hash[ra[:meta]]
    @resource.op     Hash[ra[:op]]
  end

  describe ":create action" do
    let(:ra) { Chef::RSpec::Pacemaker::Config::RA }

    it "should modify the primitive if it already exists" do
      provider = Chef::Provider::PacemakerPrimitive.new(@resource, @run_context)

      # get_cib_object_definition is invoked by load_current_resource
      # and later used to see whether to create or modify.
      expect(provider).to receive(:get_cib_object_definition).and_return(ra[:config])

      configure_cmd_prefix = "crm_resource --resource keystone"
      expected_configure_cmd_args = [
        "--set-parameter os_password --parameter-value newpasswd",
        "--delete-parameter os_tenant_name",
        "--set-parameter target-role --parameter-value Stopped --meta",
      ]

      provider.run_action :create
      expected_configure_cmd_args.each do |args|
        cmd = configure_cmd_prefix + " " + args
        expect(@chef_run).to run_execute(cmd)
      end
      expect(@resource).to be_updated
    end

    it "should create a primitive if it doesn't already exist" do
      provider = Chef::Provider::PacemakerPrimitive.new(@resource, @run_context)

      # get_cib_object_definition is invoked by load_current_resource
      # and later used to see whether to create or modify.
      expect(provider).to receive(:get_cib_object_definition).and_return(nil)

      cmd = "crm configure primitive keystone #{ra[:agent]}" + \
            ra[:params_string] + ra[:meta_string] + ra[:op_string]

      # Later, the :create action calls cib_object_exists? to check
      # that creation succeeded.
      expect(provider).to receive(:cib_object_exists?).and_return(true)

      provider.run_action :create

      expect(@chef_run).to run_execute(cmd)
      expect(@resource).to be_updated
    end

    it "should barf if the primitive has the wrong agent" do
      pending "not implemented yet"
    end
  end
end
