# frozen_string_literal: true

class Logger
  def self.configure(other)
    other.logger = new
  end

  def <<(message)
    puts(message)
  end
end
