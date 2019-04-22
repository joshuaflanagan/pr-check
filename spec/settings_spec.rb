require "spec_helper"

RSpec.describe "Settings" do
  it "calls object setters with values a Hash keyed by setter name" do
    configuration_values = {
      "Name" => "Tony",
      "AGE" => 42,
      "Phone" => "555-1212",
      "ZIP_CODE" => "90210"
    }

    Settings.init(configuration_values)

    example_class = Class.new do
      attr_accessor :name, :age, :zipcode
      attr_reader :phone
    end

    instance = example_class.new

    Settings.configure(instance)

    expect(instance.name).to eq("Tony")
    expect(instance.age).to eq(42)
    expect(instance.zipcode).to be_nil # missing underscore
    expect(instance.phone).to be_nil # no setter
  end
end
