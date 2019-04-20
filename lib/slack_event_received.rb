# frozen_string_literal: true
require 'json'

class SlackEventReceived
  def self.call(event, context)
    { statusCode: 200, body: JSON.generate('Go Serverless v1.0! Your function executed successfully!') }
  end
end
