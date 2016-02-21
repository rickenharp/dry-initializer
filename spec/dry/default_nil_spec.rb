describe "default nil" do
  before do
    class Test::Foo
      extend Dry::Initializer

      param :foo, default: nil
      param :bar, default: nil
    end
  end

  it "is assigned" do
    subject = Test::Foo.new(1)

    expect(subject.foo).to eql 1
    expect(subject.bar).to be_nil
  end
end