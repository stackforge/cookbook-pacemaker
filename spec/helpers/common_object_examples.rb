require 'mixlib/shellout'
require File.join(File.dirname(__FILE__), %w(.. .. libraries pacemaker cib_object))

shared_examples "a CIB object" do
  def expect_to_match_fixture(obj)
    expect(obj.is_a? pacemaker_object_class).to eq(true)
    fields.each do |field|
      method = field.to_sym
      expect(obj.send(method)).to eq(fixture.send(method))
    end
  end

  it "should be instantiated via Pacemaker::CIBObject.from_name" do
    Mixlib::ShellOut.any_instance.stub(:error!)
    expect_any_instance_of(Mixlib::ShellOut) \
      .to receive(:stdout) \
      .and_return(fixture.definition_string)

    obj = Pacemaker::CIBObject.from_name(fixture.name)
    expect_to_match_fixture(obj)
  end

  it "should instantiate by parsing a definition" do
    obj = Pacemaker::CIBObject.from_definition(fixture.definition_string)
    expect_to_match_fixture(obj)
  end

  it "should barf if the loaded definition's type is not colocation" do
    Mixlib::ShellOut.any_instance.stub(:error!)
    expect_any_instance_of(Mixlib::ShellOut) \
      .to receive(:stdout) \
      .and_return("clone foo blah blah")
    expect { fixture.load_definition }.to \
      raise_error(Pacemaker::CIBObject::TypeMismatch,
                  "Expected #{object_type} type but loaded definition was type clone")
  end
end
