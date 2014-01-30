require 'spec_helper'
require File.join(File.dirname(__FILE__), %w(.. .. .. ..
                              libraries pacemaker constraint colocation))
require File.join(File.dirname(__FILE__), %w(.. .. .. fixtures colocation_constraint))
require File.join(File.dirname(__FILE__), %w(.. .. .. helpers common_object_examples))

describe Pacemaker::Constraint::Colocation do
  let(:fixture) { Chef::RSpec::Pacemaker::Config::COLOCATION_CONSTRAINT.dup }

  before(:each) do
    Mixlib::ShellOut.any_instance.stub(:run_command)
  end

  def object_type
    'colocation'
  end

  def pacemaker_object_class
    Pacemaker::Constraint::Colocation
  end

  def fields
    %w(name score resources)
  end

  it_should_behave_like "a CIB object"
end
