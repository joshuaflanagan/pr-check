# frozen_string_literal: true

require "json"
require "logger"
require "init"

require "github/pull_request_approved"

module Github
  class EventReceived
    dependency :logger, Logger
    dependency :pull_request_approved, PullRequestApproved

    def self.call(event, context)
      build.call(event)
    end

    def self.build
      new.tap do |instance|
        Logger.configure(instance)
        PullRequestApproved.configure(instance)
      end
    end

    def call(event)
      github_event = event["headers"]["X-GitHub-Event"]
      logger << "Github Event: #{event}"

      if github_event == "pull_request_review"
        logger << "Got Pull Request Review event"
        payload = JSON.parse(event["body"])
        if payload["review"]["state"] == "approved"
          logger << "Handling approval event"
          pull_request_approved.call(payload)
        else
          logger << "Not an approval event"
        end
      else
        logger << "Not a review event"
      end

      {
        "statusCode" => 200
      }
    rescue => e
      logger << "UNHANDLED ERROR: #{e.inspect}\n#{e.backtrace}"
      {
        "statusCode" => 500
      }
    end
  end
end
