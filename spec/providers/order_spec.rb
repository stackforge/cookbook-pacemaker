require 'spec_helper'

this_dir = File.dirname(__FILE__)
require File.expand_path('../helpers/provider',               this_dir)
require File.expand_path('../helpers/non_runnable_resource',  this_dir)
require File.expand_path('../fixtures/order_constraint',      this_dir)

describe "Chef::Provider::PacemakerOrder" do
  # for use inside examples:
  let(:fixture) { Chef::RSpec::Pacemaker::Config::ORDER_CONSTRAINT.dup }
  # for use outside examples (e.g. when invoking shared_examples)
  fixture = Chef::RSpec::Pacemaker::Config::ORDER_CONSTRAINT.dup

  def lwrp_name
    'order'
  end

  include_context "a Pacemaker LWRP"

  before(:each) do
    @resource.score     fixture.score
    @resource.ordering fixture.ordering.dup


  end

  def cib_object_class
    Pacemaker::Constraint::Order
  end

  describe ":create action" do
    include Chef::RSpec::Pacemaker::CIBObject

    it "should modify the constraint if it has a different score" do
      new_score = '100'
      fixture.score = new_score
      expected_configure_cmd_args = [fixture.reconfigure_command]
      test_modify(expected_configure_cmd_args) do
        @resource.score new_score
      end
    end

    it "should modify the constraint if it has a resource added" do
      new_resource = 'bar:Stopped'
      expected = fixture.dup
      expected.ordering = expected.ordering.dup + ' ' + new_resource
      expected_configure_cmd_args = [expected.reconfigure_command]
      test_modify(expected_configure_cmd_args) do
        @resource.ordering expected.ordering
      end
    end

    it "should modify the constraint if it has a different ordering" do
      new_ordering = 'clone1 primitive1'
      fixture.ordering = new_ordering
      expected_configure_cmd_args = [fixture.reconfigure_command]
      test_modify(expected_configure_cmd_args) do
        @resource.ordering new_ordering
      end
    end

  end

  it_should_behave_like "a non-runnable resource", fixture

end
