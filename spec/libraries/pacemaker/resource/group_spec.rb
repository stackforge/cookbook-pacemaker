require 'spec_helper'

require File.expand_path('../../../../libraries/pacemaker/resource/group',
                         File.dirname(__FILE__))
require File.expand_path('../../../fixtures/resource_group', File.dirname(__FILE__))
require File.expand_path('../../../helpers/cib_object', File.dirname(__FILE__))
require File.expand_path('../../../helpers/meta_examples',
                         File.dirname(__FILE__))

describe Pacemaker::Resource::Group do
  let(:fixture) { Chef::RSpec::Pacemaker::Config::RESOURCE_GROUP.dup }
  let(:fixture_definition) {
    Chef::RSpec::Pacemaker::Config::RESOURCE_GROUP_DEFINITION
  }

  def object_type
    'group'
  end

  def pacemaker_object_class
    Pacemaker::Resource::Group
  end

  def fields
    %w(name members)
  end

  it_should_behave_like "a CIB object"

  it_should_behave_like "with meta attributes"

  describe "#definition_string" do
    it "should return the definition string" do
      expect(fixture.definition_string).to eq(fixture_definition)
    end

    it "should return a short definition string" do
      group = pacemaker_object_class.new('foo')
      group.definition = \
        %!group foo member1 member2 meta target-role="Started"!
      group.parse_definition
      expect(group.definition_string).to eq(<<'EOF'.chomp)
group foo member1 member2 \
         meta target-role="Started"
EOF
    end
  end

  describe "#parse_definition" do
    before(:each) do
      @parsed = pacemaker_object_class.new(fixture.name)
      @parsed.definition = fixture_definition
      @parsed.parse_definition
    end

    it "should parse the members" do
      expect(@parsed.members).to eq(fixture.members)
    end
  end
end
