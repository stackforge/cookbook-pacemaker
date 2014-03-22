require 'spec_helper'

this_dir = File.dirname(__FILE__)
require File.expand_path('../../../../libraries/pacemaker/resource/primitive',
                         this_dir)
require File.expand_path('../../../fixtures/keystone_primitive', this_dir)
require File.expand_path('../../../helpers/cib_object', this_dir)
require File.expand_path('../../../helpers/meta_examples', this_dir)

describe Pacemaker::Resource::Primitive do
  let(:fixture) { Chef::RSpec::Pacemaker::Config::KEYSTONE_PRIMITIVE.dup }
  let(:fixture_definition) {
    Chef::RSpec::Pacemaker::Config::KEYSTONE_PRIMITIVE_DEFINITION
  }

  def object_type
    'primitive'
  end

  def pacemaker_object_class
    Pacemaker::Resource::Primitive
  end

  def fields
    %w(name agent params_string meta_string op_string)
  end

  it_should_behave_like "a CIB object"

  describe "#params_string" do
    it "should return empty string with nil params" do
      fixture.params = nil
      expect(fixture.params_string).to eq("")
    end

    it "should return empty string with empty params" do
      fixture.params = {}
      expect(fixture.params_string).to eq("")
    end

    it "should return a resource params string" do
      fixture.params = {
        "foo" => "bar",
        "baz" => "qux",
      }
      expect(fixture.params_string).to eq(%'params baz="qux" foo="bar"')
    end
  end

  describe "#op_string" do
    it "should return empty string with nil op" do
      fixture.op = nil
      expect(fixture.op_string).to eq("")
    end

    it "should return empty string with empty op" do
      fixture.op = {}
      expect(fixture.op_string).to eq("")
    end

    it "should return a resource op string" do
      fixture.op = {
        "monitor" => {
          "foo" => "bar",
          "baz" => "qux",
        }
      }
      expect(fixture.op_string).to eq(%'op monitor baz="qux" foo="bar"')
    end
  end

  it_should_behave_like "with meta attributes"

  describe "#definition_string" do
    it "should return the definition string" do
      expect(fixture.definition_string).to eq(fixture_definition)
    end

    it "should return a short definition string" do
      primitive = pacemaker_object_class.new('foo')
      primitive.definition = \
        %!primitive foo ocf:heartbeat:IPaddr2 params foo="bar"!
      primitive.parse_definition
      expect(primitive.definition_string).to eq(<<'EOF'.chomp)
primitive foo ocf:heartbeat:IPaddr2 \
         params foo="bar"
EOF
    end
  end

  describe "#quoted_definition_string" do
    it "should return the quoted definition string" do
      primitive = pacemaker_object_class.new('foo')
      primitive.definition = <<'EOF'.chomp
primitive foo ocf:openstack:keystone \
         params bar="baz\\qux" bar2="baz'qux"
EOF
      primitive.parse_definition
      expect(primitive.quoted_definition_string).to eq(<<'EOF'.chomp)
'primitive foo ocf:openstack:keystone \\
         params bar="baz\\qux" bar2="baz\'qux"'
EOF
    end
  end

  describe "#parse_definition" do
    before(:each) do
      @parsed = pacemaker_object_class.new(fixture.name)
      @parsed.definition = fixture_definition
      @parsed.parse_definition
    end

    it "should parse the agent" do
      expect(@parsed.agent).to eq(fixture.agent)
    end
  end
end
