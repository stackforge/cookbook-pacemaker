require 'spec_helper'
require File.expand_path('../../../../libraries/pacemaker/resource/ms',
                         File.dirname(__FILE__))
require File.expand_path('../../../fixtures/ms_resource', File.dirname(__FILE__))
require File.expand_path('../../../helpers/cib_object', File.dirname(__FILE__))
require File.expand_path('../../../helpers/meta_examples',
                         File.dirname(__FILE__))

describe Pacemaker::Resource::MasterSlave do
  let(:fixture) { Chef::RSpec::Pacemaker::Config::MS_RESOURCE.dup }
  let(:fixture_definition) {
    Chef::RSpec::Pacemaker::Config::MS_RESOURCE_DEFINITION
  }

  before(:each) do
    Mixlib::ShellOut.any_instance.stub(:run_command)
  end

  def object_type
    'ms'
  end

  def pacemaker_object_class
    Pacemaker::Resource::MasterSlave
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
      ms = Pacemaker::Resource::MasterSlave.new('foo')
      ms.definition = \
        %!ms ms1 primitive1 meta globally-unique="true"!
      ms.parse_definition
      expect(ms.definition_string).to eq(<<'EOF'.chomp)
ms ms1 primitive1 \
         meta globally-unique="true"
EOF
    end
  end

  describe "#parse_definition" do
    before(:each) do
      @parsed = Pacemaker::Resource::MasterSlave.new(fixture.name)
      @parsed.definition = fixture_definition
      @parsed.parse_definition
    end

    it "should parse the rsc" do
      expect(@parsed.rsc).to eq(fixture.rsc)
    end
  end
end
