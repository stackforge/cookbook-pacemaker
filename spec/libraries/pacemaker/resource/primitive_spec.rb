require 'spec_helper'
require_relative File.join(%w(.. .. .. .. libraries pacemaker resource primitive))
require_relative File.join(%w(.. .. .. helpers keystone_primitive))

describe Pacemaker::Resource::Primitive do
  before(:each) do
    @primitive = Chef::RSpec::Pacemaker::Config::KEYSTONE_PRIMITIVE.dup
    Mixlib::ShellOut.any_instance.stub(:run_command)
  end

  it "should be instantiated via Pacemaker::CIBObject.from_name" do
    Mixlib::ShellOut.any_instance.stub(:error!)
    expect_any_instance_of(Mixlib::ShellOut) \
      .to receive(:stdout) \
      .and_return(@primitive.definition_string)

    obj = Pacemaker::CIBObject.from_name(@primitive.name)
    expect(obj.is_a? Pacemaker::Resource::Primitive).to be_true
  end

  it "should barf if the loaded definition's type is not primitive" do
    Mixlib::ShellOut.any_instance.stub(:error!)
    expect_any_instance_of(Mixlib::ShellOut) \
      .to receive(:stdout) \
      .and_return("clone foo blah blah")
    expect { @primitive.load_definition }.to \
      raise_error(Pacemaker::CIBObject::TypeMismatch,
                  "Expected primitive type but loaded definition was type clone")
  end

  describe "#params_string" do
    it "should return empty string with nil params" do
      @primitive.params = nil
      expect(@primitive.params_string).to eq("")
    end

    it "should return empty string with empty params" do
      @primitive.params = {}
      expect(@primitive.params_string).to eq("")
    end

    it "should return a resource params string" do
      @primitive.params = {
        "foo" => "bar",
        "baz" => "qux",
      }
      expect(@primitive.params_string).to eq(%' params baz="qux" foo="bar"')
    end
  end

  describe "#meta_string" do
    it "should return empty string with nil meta" do
      @primitive.meta = nil
      expect(@primitive.meta_string).to eq("")
    end

    it "should return empty string with empty meta" do
      @primitive.meta = {}
      expect(@primitive.meta_string).to eq("")
    end

    it "should return a resource meta string" do
      @primitive.meta = {
        "foo" => "bar",
        "baz" => "qux",
      }
      expect(@primitive.meta_string).to eq(%' meta baz="qux" foo="bar"')
    end
  end

  describe "#op_string" do
    it "should return empty string with nil op" do
      @primitive.op = nil
      expect(@primitive.op_string).to eq("")
    end

    it "should return empty string with empty op" do
      @primitive.op = {}
      expect(@primitive.op_string).to eq("")
    end

    it "should return a resource op string" do
      @primitive.op = {
        "monitor" => {
          "foo" => "bar",
          "baz" => "qux",
        }
      }
      expect(@primitive.op_string).to eq(%' op monitor baz="qux" foo="bar"')
    end
  end

  describe "::extract_hash" do
    it "should extract a hash from config" do
      expect(@primitive.class.extract_hash(@primitive.definition_string, "params")).to \
        eq(Hash[@primitive.params])
    end
  end

  describe "#definition_string" do
    it "should return the definition string" do
      expect(@primitive.definition_string).to \
        eq(Chef::RSpec::Pacemaker::Config::KEYSTONE_PRIMITIVE_DEFINITION)
    end
  end

  describe "#parse_definition" do
    before(:each) do
      @parsed = Pacemaker::Resource::Primitive.new(@primitive.name)
      @parsed.definition = Chef::RSpec::Pacemaker::Config::KEYSTONE_PRIMITIVE_DEFINITION
      @parsed.parse_definition
    end

    it "should parse the agent" do
      expect(@parsed.agent).to eq(@primitive.agent)
    end
  end
end
