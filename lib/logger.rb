# frozen_string_literal: true

class Logger
  def self.configure(instance)
    instance.logger = new
  end

  def <<(message)
    puts(message)
  end
end
