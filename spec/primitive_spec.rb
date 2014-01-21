require 'chef/application'
require_relative 'spec_helper'

describe "Chef::Provider::PacemakerPrimitive" do
  before do
    @chef_run = ::ChefSpec::Runner.new(step_into: ['pacemaker_primitive']) #::OPENSUSE_OPTS
    @chef_run.converge "pacemaker::default"
    @node = @chef_run.node

    @cookbook_collection = Chef::CookbookCollection.new([])
    @events = Chef::EventDispatch::Dispatcher.new
    @run_context = Chef::RunContext.new(@node, @cookbook_collection, @events)

    @resource = Chef::Resource::PacemakerPrimitive.new("keystone", @run_context)

    @resource.agent "ocf:openstack:keystone"
    ra_params = {
      "os_auth_url"    => "http://localhost:5000/v2.0",
      "os_tenant_name" => "openstack",
      "os_username"    => "admin",
      "os_password"    => "adminpw",
      "user"           => "openstack-keystone"
    }
    ra_meta = {
      "target-role" => "Started",
      "is-managed"  => "true"
    }
    ra_op = {
      "monitor" => { "interval" => "10s" }
    }

    @resource.params ra_params
    @resource.meta   ra_meta
    @resource.op     ra_op
  end

  describe ":create action" do
    it "should do nothing if the primitive already exists" do
      provider = Chef::Provider::PacemakerPrimitive.new(@resource, @run_context)
      expect(provider).to receive(:cib_object_exists?).at_least(:once).and_return(true)
      expect(provider).to receive(:get_cib_object_definition).and_return(@config)
      expect(Mixlib::ShellOut).not_to receive(:new)
      provider.run_action :create
    end

    # it "should create a primitive" do
    #   pending "foo"
    #   @resource.run_action :create
    # end
  end

  # let(:chef_run) {
  #   ChefSpec::Runner.new(step_into: ['my_lwrp']).converge('foo::default')
  # }
  # 
  # it 'installs the foo package through my_lwrp' do
  #   expect(chef_run).to install_package('foo')
  # end
end
