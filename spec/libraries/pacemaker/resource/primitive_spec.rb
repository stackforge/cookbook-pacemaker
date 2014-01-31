require 'spec_helper'
require_relative File.join(%w(.. .. .. .. libraries pacemaker resource primitive))
require_relative File.join(%w(.. .. .. fixtures keystone_primitive))
require_relative File.join(%w(.. .. .. helpers common_object_examples))

describe Pacemaker::Resource::Primitive do
  let(:fixture) { Chef::RSpec::Pacemaker::Config::KEYSTONE_PRIMITIVE.dup }

  before(:each) do
    Mixlib::ShellOut.any_instance.stub(:run_command)
  end

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

  describe "#meta_string" do
    it "should return empty string with nil meta" do
      fixture.meta = nil
      expect(fixture.meta_string).to eq("")
    end

    it "should return empty string with empty meta" do
      fixture.meta = {}
      expect(fixture.meta_string).to eq("")
    end

    it "should return a resource meta string" do
      fixture.meta = {
        "foo" => "bar",
        "baz" => "qux",
      }
      expect(fixture.meta_string).to eq(%'meta baz="qux" foo="bar"')
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

  describe "::extract_hash" do
    it "should extract a params hash from config" do
      expect(fixture.class.extract_hash(fixture.definition_string, "params")).to \
        eq(Hash[fixture.params])
    end

    it "should extract an op start hash from config" do
      expect(fixture.class.extract_hash(fixture.definition_string, 'op start')).to \
        eq(Hash[fixture.op]['start'])
    end

    it "should extract an op monitor hash from config" do
      expect(fixture.class.extract_hash(fixture.definition_string, 'op monitor')).to \
        eq(Hash[fixture.op]['monitor'])
    end
  end

  describe "#definition_string" do
    it "should return the definition string" do
      expect(fixture.definition_string).to \
        eq(Chef::RSpec::Pacemaker::Config::KEYSTONE_PRIMITIVE_DEFINITION)
    end
  end

  describe "#parse_definition" do
    before(:each) do
      @parsed = Pacemaker::Resource::Primitive.new(fixture.name)
      @parsed.definition = Chef::RSpec::Pacemaker::Config::KEYSTONE_PRIMITIVE_DEFINITION
      @parsed.parse_definition
    end

    it "should parse the agent" do
      expect(@parsed.agent).to eq(fixture.agent)
    end
  end
end
