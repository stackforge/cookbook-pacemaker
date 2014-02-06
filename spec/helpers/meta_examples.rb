shared_examples "with meta attributes" do
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
end
