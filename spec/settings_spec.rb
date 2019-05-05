require "spec_helper"
require "settings"

RSpec.describe "Settings" do
  it "calls object setters with values from a Hash keyed by setter name" do
    configuration_values = {
      "OWNER_Name" => "Tony",
      "OWNER_AGE" => 42,
      "OWNER_Phone" => "555-1212",
      "OWNER_ZIP_CODE" => "90210",
      "PLANET" => "earth",
      "OTHER_WEIGHT" => 120,
      "OTHER_HEIGHT" => 72,
    }

    Settings.init(configuration_values)

    example_class = Class.new do
      attr_accessor :name, :age, :zipcode, :weight, :height, :planet
      attr_reader :phone
    end

    instance = example_class.new

    Settings.configure("owner", instance)

    expect(instance.name).to eq("Tony")
    expect(instance.age).to eq(42)
    expect(instance.zipcode).to be_nil # missing underscore
    expect(instance.phone).to be_nil # no setter
    expect(instance.weight).to be_nil # no namespace
    expect(instance.height).to be_nil # wrong namespace
    expect(instance.planet).to eq("earth") # global namespace
  end
end
