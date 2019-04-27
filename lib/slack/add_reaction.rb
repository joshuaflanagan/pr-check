# frozen_string_literal: true

require "slack/http"

module Slack
  class AddReaction
    dependency :http, Slack::Http

    def self.call(channel:, timestamp:, reaction:)
      build.call(channel: channel, timestamp: timestamp, reaction: reaction)
    end

    def self.build
      new.tap do |instance|
        Slack::Http.configure(instance)
      end
    end

    def call(channel:, timestamp:, reaction:)
      # Documentation https://api.slack.com/methods/reactions.add
      payload = {
        "channel" => channel,
        "timestamp" => timestamp,
        "name" => reaction,
      }
      http.call(:post, "https://slack.com/api/reactions.add", payload: payload)
    end
  end
end
