require 'spec_helper'

this_dir = File.dirname(__FILE__)
require File.expand_path('../helpers/provider', this_dir)
require File.expand_path('../fixtures/colocation_constraint', this_dir)

describe "Chef::Provider::PacemakerColocation" do
  # for use inside examples:
  let(:fixture) { Chef::RSpec::Pacemaker::Config::COLOCATION_CONSTRAINT.dup }
  # for use outside examples (e.g. when invoking shared_examples)
  fixture = Chef::RSpec::Pacemaker::Config::COLOCATION_CONSTRAINT.dup

  def lwrp_name
    'colocation'
  end

  include_context "a Pacemaker LWRP"

  before(:each) do
    @resource.score     fixture.score
    @resource.resources fixture.resources.dup
  end

  def cib_object_class
    Pacemaker::Constraint::Colocation
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
      expected.resources = expected.resources.dup + [new_resource]
      expected_configure_cmd_args = [expected.reconfigure_command]
      test_modify(expected_configure_cmd_args) do
        @resource.resources expected.resources
      end
    end

    it "should modify the constraint if it has a different resource" do
      new_resources = ['bar:Started']
      fixture.resources = new_resources
      expected_configure_cmd_args = [fixture.reconfigure_command]
      test_modify(expected_configure_cmd_args) do
        @resource.resources new_resources
      end
    end

  end

  describe ":delete action" do
    it_should_behave_like "action on non-existent resource", \
      :delete, "crm configure delete #{fixture.name}", nil
  end

end
