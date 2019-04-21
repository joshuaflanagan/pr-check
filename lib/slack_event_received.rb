# frozen_string_literal: true

require "json"
require "init"

class SlackEventReceived
  dependency :logger, ::Logger

  def self.call(event, context)
    build.call(event)
  end

  def self.build
    instance = new
    Logger.configure(instance)
    instance
  end

  def call(event)
    payload = JSON.parse(event["body"])

    slack_event_type = payload["type"]
    unless slack_event_type == "url_verification"
      logger << "UNRECOGNIZED TYPE: #{event}"
      return fail_response(400)
    end

    challenge = payload["challenge"]
    unless challenge
      logger << "NO CHALLENGE: #{event}"
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
