# frozen_string_literal: true
require 'json'

class SlackEventReceived
  def self.call(event, context)
    new.call(event)
  end

  def call(event)
    payload = JSON.parse(event["body"])

    slack_event_type = payload["type"]
    unless slack_event_type == "url_verification"
      return fail_response(400)
    end

    challenge = payload["challenge"]
    unless challenge
      return fail_response(400)
    end

    body = {
      "challenge" => payload["challenge"]
    }
    success_response(body)
  end

  def success_response(body)
    {
      "statusCode" => 200,
      "body" => JSON.generate(body)
    }
  end

  def fail_response(status)
    { "statusCode" => status }
  end
end
