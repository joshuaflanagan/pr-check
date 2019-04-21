require "spec_helper"
require "slack_event_received"

RSpec.describe "Handling Slack events" do
  let(:lambda_context) { Object.new }
  let(:lambda_event) {
    # This is the hash built by API Gateway to invoke the Lambda
    {
      "body" => JSON.generate(slack_payload)
    }
  }

  subject(:handler) { SlackEventReceived.new }

  context "when an unrecognized event occurs" do
    let(:slack_payload) {
      {
        "token" => "Jhj5dZrVaK7ZwHHjRyZWjbDl",
        "challenge" => "ignored",
        "type" => "unrecognized"
      }
    }

    it "returns a 400 status" do
      response = handler.call(lambda_event)

      expect(response.fetch("statusCode")).to eq(400)
    end
  end

  context "when a url_verifications event occurs" do
    let(:slack_payload) {
      # example payload from https://api.slack.com/events/url_verification
      {
        "token" => "Jhj5dZrVaK7ZwHHjRyZWjbDl",
        "type" => "url_verification"
      }
    }

    context "and the body contains a 'challenge' value" do
      before do
        slack_payload["challenge"] = "CHALLENGE VALUE"
      end

      it "returns a 200 status" do
        response = handler.call(lambda_event)

        expect(response.fetch("statusCode")).to eq(200)
      end

      it "returns the challenge phrase in a JSON document" do
        response = handler.call(lambda_event)

        body = response.fetch("body")
        parsed_body = JSON.parse(body)
        expect(parsed_body["challenge"]).to eq("CHALLENGE VALUE")
      end
    end

    context "and the body does not contain a challenge value" do
      before do
        slack_payload.delete("challenge")
      end

      it "returns a 400 status" do
        response = handler.call(lambda_event)

        expect(response.fetch("statusCode")).to eq(400)
      end
    end
  end

  context "when an event_callback event occurs" do
    let(:slack_event) {
      {
      "type" => "some_event_type"
      }
    }
    let(:slack_payload) {
      {
        "token"=>"hMUbwB9999KdLbmmuxALHn8Z",
        "team_id"=>"T0TEAMID",
        "api_app_id"=>"APP12345",
        "event"=> slack_event,
        "type"=>"event_callback",
        "event_id"=>"Ev111Z1AM6",
        "event_time"=>1555820196,
        "authed_users"=>["USER5555"]
      }
    }

    it "returns a 200 status" do
      response = handler.call(lambda_event)

      expect(response.fetch("statusCode")).to eq(200)
    end

    context "and the event type is link_shared" do
      let(:slack_event) {
        {
          "type"=>"link_shared",
          "user"=>"USER5555",
          "channel"=>"GG09876",
          "message_ts"=>"1555820195.000400",
          "links"=> [
            {
              "url"=>"https://github.com/ExampleUser/example_repo/pull/4204",
              "domain"=>"github.com"
            }
          ]
        }
      }

      it "returns a 200 status" do
        response = handler.call(lambda_event)

        expect(response.fetch("statusCode")).to eq(200)
      end

      #TODO: can actually capture more than one PR in single mention.
      #Do we want to support that? or do we just store the first?
      #How will we know which PR the reaction belongs to?
      it "captures the PR and message timestamp" do
        handler.call(lambda_event)

        mentions_store = handler.mentions_store
        saved_mention = mentions_store.last_mention

        expect(saved_mention[:pr_id]).to eq("ExampleUser/example_repo/pull/4204")
        expect(saved_mention[:mention_id]).to eq("1555820195.000400")
      end
    end
  end

end
