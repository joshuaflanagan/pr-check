# frozen_string_literal: true

class CustomLogger
  def self.configure(other)
    other.logger = new
  end

  def <<(message)
    puts(message)
  end
end
