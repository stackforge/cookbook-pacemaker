require 'spec_helper'

this_dir = File.dirname(__FILE__)
require File.expand_path('../helpers/runnable_resource', this_dir)
require File.expand_path('../fixtures/ms_resource', this_dir)

describe "Chef::Provider::PacemakerMs" do
  # for use inside examples:
  let(:fixture) { Chef::RSpec::Pacemaker::Config::MS_RESOURCE.dup }
  # for use outside examples (e.g. when invoking shared_examples)
  fixture = Chef::RSpec::Pacemaker::Config::MS_RESOURCE.dup

  def lwrp_name
    'ms'
  end

  include_context "a Pacemaker LWRP"

  before(:each) do
    @resource.rsc  fixture.rsc.dup
    @resource.meta Hash[fixture.meta.dup]


  end

  def cib_object_class
    Pacemaker::Resource::MasterSlave
  end

  describe ":create action" do
    include Chef::RSpec::Pacemaker::CIBObject

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
