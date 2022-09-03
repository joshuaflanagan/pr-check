# frozen_string_literal: true

require "custom_logger"
require "json"
require "init"
require "pull_request_identifier"
require "mark_pr_approved"

class SlackEventReceived
  dependency :logger, CustomLogger
  dependency :mentions_store, MentionsStore
  dependency :invoke_mark_pr_approved, MarkPrApproved::Invoke

  def self.call(event, context)
    build.call(event)
  end

  def self.build
    new.tap do |instance|
      CustomLogger.configure(instance)
      MentionsStore.configure(instance)
      MarkPrApproved::Invoke.configure(instance)
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
      msg_source = slack_event["source"]
      if msg_source != "conversations_history" # sent message
        return fail_response(200, "Ignoring links from source '#{msg_source}'")
      end
      github_links = slack_event["links"].select{|link|
        link["domain"] == "github.com"
      }.uniq
      if github_links.length == 1
        url = github_links[0].fetch("url")
        pr_id = PullRequestIdentifier.(url)
        if pr_id
          channel = slack_event.fetch("channel")
          message_ts = slack_event.fetch("message_ts")
          mention_id = "#{channel}|#{message_ts}"
          logger << "Storing a mention of #{url} in channel #{channel} at #{message_ts}"
          mentions_store.save(pr_id: pr_id, mention_id: mention_id)
          invoke_mark_pr_approved.(pr_id)
        else
          logger << "Not a pull request link: #{url}"
        end
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

  def fail_response(status, message=null)
    logger << message if message
    { "statusCode" => status }
  end
end
