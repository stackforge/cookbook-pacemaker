require 'spec_helper'
require File.expand_path('../../../../libraries/pacemaker/constraint/colocation',
                         File.dirname(__FILE__))
require File.expand_path('../../../fixtures/colocation_constraint', File.dirname(__FILE__))
require File.expand_path('../../../helpers/common_object_examples', File.dirname(__FILE__))

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
