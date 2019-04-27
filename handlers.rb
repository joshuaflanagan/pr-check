# frozen_string_literal: true

$LOAD_PATH.unshift(File.expand_path("lib", __dir__))
load "vendor/bundle/bundler/setup.rb"

require "http"
require "slack_event_received"
require "slack/add_reaction"

module Handlers
  def self.slack_event_received(event:, context:)
    SlackEventReceived.(event, context)
  end

  def self.github_event_received(event:, context:)
    puts event.inspect
    body = JSON.parse(event["body"])
    puts body.inspect
    {
      "statusCode" => 200,
    }
  end

  # TODO:
  # - load channel and timestamp from DB record
  # - load reaction from ENV (: separated?)
  # - load token from Amazon Secrets?
  def self.test_reaction(event:, context:)
    body = JSON.parse(event["body"])

    reaction = body["reaction"] || "three"
    channel = body["channel"] || "GGFEQAZRB"
    timestamp = body["timestamp"] || "1555853747.000200"

    begin
      Slack::AddReaction.(channel: channel, timestamp: timestamp, reaction: reaction)
    rescue Slack::Http::Error => e
      return {
        "statusCode" => 500,
        "body" => JSON.generate({errorStatus: e.response.code, errorMessage: e.response.body.to_s})
      }
    end

    {
      "statusCode" => 200
    }
  end
end
