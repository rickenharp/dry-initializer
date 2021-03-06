describe "subclassing" do
  before do
    class Test::Foo
      extend Dry::Initializer::Mixin

      param  :foo
      option :bar
    end

    class Test::Bar < Test::Foo
      param  :baz
      option :qux
    end
  end

  let(:instance_of_superclass) do
    Test::Foo.new 1, bar: 3
  end

  let(:instance_of_subclass) do
    Test::Bar.new 1, 2, bar: 3, qux: 4
  end

  it "preserves definitions made in the superclass" do
    expect(instance_of_subclass.foo).to eql 1
    expect(instance_of_subclass.baz).to eql 2
    expect(instance_of_subclass.bar).to eql 3
    expect(instance_of_subclass.qux).to eql 4
  end

  it "does not pollute superclass with definitions from subclass" do
    expect(instance_of_superclass).not_to respond_to :baz
    expect(instance_of_superclass).not_to respond_to :qux
  end
end
