require 'spec_helper'

this_dir = File.dirname(__FILE__)
require File.expand_path('../../../../libraries/pacemaker/resource/clone', this_dir)
require File.expand_path('../../../fixtures/clone_resource', this_dir)
require File.expand_path('../../../helpers/cib_object', this_dir)
require File.expand_path('../../../helpers/meta_examples', this_dir)

describe Pacemaker::Resource::Clone do
  let(:fixture) { Chef::RSpec::Pacemaker::Config::CLONE_RESOURCE.dup }
  let(:fixture_definition) {
    Chef::RSpec::Pacemaker::Config::CLONE_RESOURCE_DEFINITION
  }

  def object_type
    'clone'
  end

  def pacemaker_object_class
    Pacemaker::Resource::Clone
  end

  def fields
    %w(name rsc)
  end

  it_should_behave_like "a CIB object"

  it_should_behave_like "with meta attributes"

  describe "#definition_string" do
    it "should return the definition string" do
      expect(fixture.definition_string).to eq(fixture_definition)
    end

    it "should return a short definition string" do
      clone = pacemaker_object_class.new('foo')
      clone.definition = \
        %!clone clone1 primitive1 meta globally-unique="true"!
      clone.parse_definition
      expect(clone.definition_string).to eq(<<'EOF'.chomp)
clone clone1 primitive1 \
         meta globally-unique="true"
EOF
    end
  end

  describe "#parse_definition" do
    before(:each) do
      @parsed = pacemaker_object_class.new(fixture.name)
      @parsed.definition = fixture_definition
      @parsed.parse_definition
    end

    it "should parse the rsc" do
      expect(@parsed.rsc).to eq(fixture.rsc)
    end
  end
end
