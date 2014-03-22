require 'spec_helper'

this_dir = File.dirname(__FILE__)
require File.expand_path('../../../../libraries/pacemaker/constraint/colocation',
                         this_dir)
require File.expand_path('../../../fixtures/colocation_constraint', this_dir)
require File.expand_path('../../../helpers/cib_object', this_dir)

describe Pacemaker::Constraint::Colocation do
  let(:fixture) { Chef::RSpec::Pacemaker::Config::COLOCATION_CONSTRAINT.dup }
  let(:fixture_definition) {
    Chef::RSpec::Pacemaker::Config::COLOCATION_CONSTRAINT_DEFINITION
  }

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

  describe "#definition_string" do
    it "should return the definition string" do
      expect(fixture.definition_string).to eq(fixture_definition)
    end

    it "should return a short definition string" do
      colocation = pacemaker_object_class.new('foo')
      colocation.definition = \
        %!colocation colocation1 -inf: rsc1 rsc2!
      colocation.parse_definition
      expect(colocation.definition_string).to eq(<<'EOF'.chomp)
colocation colocation1 -inf: rsc1 rsc2
EOF
    end
  end

  describe "#parse_definition" do
    before(:each) do
      @parsed = pacemaker_object_class.new(fixture.name)
      @parsed.definition = fixture_definition
      @parsed.parse_definition
    end

    it "should parse the score" do
      expect(@parsed.score).to eq(fixture.score)
    end

    it "should parse the resources" do
      expect(@parsed.resources).to eq(fixture.resources)
    end

  end
end
