# frozen_string_literal: true

require "json"
require "init"

class SlackEventReceived
  dependency :logger, ::Logger
  dependency :mentions_store, MentionsStore

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

    slack_message_type = payload["type"]
    # temporary, so slack doesnt disable our app
    if slack_message_type == "event_callback"
      slack_event = payload.fetch("event")
      slack_event_type = slack_event.fetch("type")
      if slack_event_type == "link_shared"
        first_github_link = slack_event["links"].detect{|link|
          link["domain"] == "github.com"
        }
        if first_github_link
          url = first_github_link.fetch("url")
          pr_id = url.split(/github\.com\//, 2).last
          mention_id = slack_event.fetch("message_ts")
          mentions_store.save(pr_id: pr_id, mention_id: mention_id)
        end
      else
        logger << "UNHANDLED EVENT CALLBACK: #{event}"
      end
      return success_response({ok: true})
    end
    unless slack_message_type == "url_verification"
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
