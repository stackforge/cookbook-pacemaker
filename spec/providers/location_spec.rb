require 'spec_helper'

this_dir = File.dirname(__FILE__)
require File.expand_path('../helpers/provider',               this_dir)
require File.expand_path('../helpers/non_runnable_resource',  this_dir)
require File.expand_path('../fixtures/location_constraint',   this_dir)

describe "Chef::Provider::PacemakerLocation" do
  # for use inside examples:
  let(:fixture) { Chef::RSpec::Pacemaker::Config::LOCATION_CONSTRAINT.dup }
  # for use outside examples (e.g. when invoking shared_examples)
  fixture = Chef::RSpec::Pacemaker::Config::LOCATION_CONSTRAINT.dup

  def lwrp_name
    'location'
  end

  include_context "a Pacemaker LWRP"

  before(:each) do
    @resource.rsc   fixture.rsc
    @resource.score fixture.score
    @resource.node  fixture.node.dup

  end

  def cib_object_class
    Pacemaker::Constraint::Location
  end

  describe ":create action" do
    include Chef::RSpec::Pacemaker::CIBObject

    it "should modify the constraint if it has a different resource" do
      new_resource = 'group2'
      fixture.rsc = new_resource
      expected_configure_cmd_args = [fixture.reconfigure_command]
      test_modify(expected_configure_cmd_args) do
        @resource.rsc new_resource
      end
    end

    it "should modify the constraint if it has a different score" do
      new_score = '100'
      fixture.score = new_score
      expected_configure_cmd_args = [fixture.reconfigure_command]
      test_modify(expected_configure_cmd_args) do
        @resource.score new_score
      end
    end

    it "should modify the constraint if it has a different node" do
      new_node = 'node2'
      fixture.node = new_node
      expected_configure_cmd_args = [fixture.reconfigure_command]
      test_modify(expected_configure_cmd_args) do
        @resource.node new_node
      end
    end

  end

  it_should_behave_like "a non-runnable resource", fixture

end
