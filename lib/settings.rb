# frozen_string_literal: true

# Super-simple approach to push configuration values in to objects
class Settings
  def self.init(values)
    @values = values
  end

  def self.configure(namespace, other)
    @values.each do |key, value|
      setting_ns, setting = key.split("_", 2)
      if setting_ns.downcase == namespace
        method_name = "#{setting.downcase}=".to_sym
        if other.respond_to?(method_name)
          other.public_send(method_name, value)
        end
      end
    end
  end
end
