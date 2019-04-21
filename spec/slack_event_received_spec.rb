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

end
