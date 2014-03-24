require 'spec_helper'
require File.expand_path('../../../../libraries/pacemaker/resource/clone',
                         File.dirname(__FILE__))
require File.expand_path('../../../fixtures/clone_resource', File.dirname(__FILE__))
require File.expand_path('../../../helpers/cib_object', File.dirname(__FILE__))
require File.expand_path('../../../helpers/meta_examples',
                         File.dirname(__FILE__))

describe Pacemaker::Resource::Clone do
  let(:fixture) { Chef::RSpec::Pacemaker::Config::CLONE_RESOURCE.dup }
  let(:fixture_definition) {
    Chef::RSpec::Pacemaker::Config::CLONE_RESOURCE_DEFINITION
  }

  before(:each) do
    Mixlib::ShellOut.any_instance.stub(:run_command)
  end

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
