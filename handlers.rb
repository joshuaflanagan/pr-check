# frozen_string_literal: true

$LOAD_PATH.unshift(File.expand_path("lib", __dir__))
load "vendor/bundle/bundler/setup.rb"

require "http"
require "slack_event_received"
require "slack/add_reaction"
require "github/event_received"
require "mark_pr_approved"

module Handlers
  def self.slack_event_received(event:, context:)
    SlackEventReceived.(event, context)
  end

  def self.github_event_received(event:, context:)
    Github::EventReceived.(event, context)
  end

  def self.mark_pr_approved(event:, context:)
    MarkPrApproved.(event, context)
  end

  # TODO:
  # - load channel and timestamp from DB record
  # - load reaction from ENV (: separated?)
  # - load token from Amazon Secrets?
  def self.test_reaction(event:, context:)
    require "custom_logger"
    logger = CustomLogger.new
    logger << "test_reaction context:"
    logger << "  aws_request_id #{context.aws_request_id}"
    logger << "  log_group_name #{context.log_group_name}"
    logger << "  log_stream_name #{context.log_stream_name}"
    logger << "test_reaction event: #{event}"
    body = JSON.parse(event["body"])


    reaction = body["reaction"] || "three"
    channel = body["channel"] || "GGFEQAZRB"
    timestamp = body["timestamp"] || "1555853747.000200"

    begin
      Slack::AddReaction.(channel: channel, timestamp: timestamp, reaction: reaction)
    rescue Slack::Http::Error => e
      logger << "test_reaction error: #{event}"
      return {
        "statusCode" => 500,
        "body" => JSON.generate({errorStatus: e.response.code, errorMessage: e.response.body.to_s})
      }
    end

    logger << "test_reaction success"
    {
      "statusCode" => 200
    }
  end
end
