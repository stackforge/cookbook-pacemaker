require 'spec_helper'

this_dir = File.dirname(__FILE__)
require File.expand_path('../../../../libraries/pacemaker/constraint/order',
                         this_dir)
require File.expand_path('../../../fixtures/order_constraint', this_dir)
require File.expand_path('../../../helpers/cib_object', this_dir)

describe Pacemaker::Constraint::Order do
  let(:fixture) { Chef::RSpec::Pacemaker::Config::ORDER_CONSTRAINT.dup }
  let(:fixture_definition) {
    Chef::RSpec::Pacemaker::Config::ORDER_CONSTRAINT_DEFINITION
  }

  def object_type
    'order'
  end

  def pacemaker_object_class
    Pacemaker::Constraint::Order
  end

  def fields
    %w(name score ordering)
  end

  it_should_behave_like "a CIB object"

  describe "#definition_string" do
    it "should return the definition string" do
      expect(fixture.definition_string).to eq(fixture_definition)
    end

    it "should return a short definition string" do
      order = pacemaker_object_class.new('foo')
      order.definition = \
        %!order order1 Mandatory: rsc1 rsc2!
      order.parse_definition
      expect(order.definition_string).to eq(<<'EOF'.chomp)
order order1 Mandatory: rsc1 rsc2
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

    it "should parse the ordering" do
      expect(@parsed.ordering).to eq(fixture.ordering)
    end

  end
end
