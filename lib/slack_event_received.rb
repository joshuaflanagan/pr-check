# frozen_string_literal: true

require "json"
require "init"
require "pull_request_identifier"
require "mark_pr_approved"

class SlackEventReceived
  dependency :logger, ::Logger
  dependency :mentions_store, MentionsStore
  dependency :pull_request_identifier, PullRequestIdentifier

  def self.call(event, context)
    build.call(event)
  end

  def self.build
    new.tap do |instance|
      Logger.configure(instance)
      MentionsStore.configure(instance)
    end
  end

  def call(event)
    logger << "Slack Event: #{event}"
    payload = JSON.parse(event["body"])

    slack_message_type = payload["type"]

    case slack_message_type
    when "url_verification"
      url_verify(payload)
    when "event_callback"
      slack_event(payload)
    else
      logger << "UNRECOGNIZED TYPE: #{event}"
      return fail_response(400)
    end
  end

  def slack_event(payload)
    slack_event = payload.fetch("event")
    slack_event_type = slack_event.fetch("type")
    if slack_event_type == "link_shared"
      logger << "Handling link_shared event"
      github_links = slack_event["links"].select{|link|
        link["domain"] == "github.com"
      }
      if github_links.length == 1
        url = github_links[0].fetch("url")
        logger << "Storing a mention of #{url}"
        pr_id = pull_request_identifier.(url)
        channel = slack_event.fetch("channel")
        message_ts = slack_event.fetch("message_ts")
        mention_id = "#{channel}|#{message_ts}"
        mentions_store.save(pr_id: pr_id, mention_id: mention_id)
        MarkPrApproved::Invoke.(pr_id)
      else
        logger << "Not storing an ambiguous mention. Links: #{github_links}"
      end
    else
      logger << "UNHANDLED EVENT CALLBACK: #{payload}"
    end
    return success_response({ok: true})
  rescue => e
    logger << "ERROR: #{e.inspect}\n#{e.backtrace}"
    fail_response(500)
  end

  def url_verify(payload)
    logger << "Handling URL verification"
    challenge = payload["challenge"]
    unless challenge
      logger << "NO CHALLENGE: #{payload}"
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
