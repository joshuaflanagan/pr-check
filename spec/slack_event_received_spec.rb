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
      let(:links) { [] }

      let(:slack_event) {
        {
          "type"=>"link_shared",
          "user"=>"USER5555",
          "channel"=>"CHANNEL200",
          "message_ts"=>"1555820195.000400",
          "links"=> links,
          "source"=>"conversations_history"
        }
      }

      context "containing a single github link" do
        let(:url) { "https://github.com/ExampleUser/example_repo/pull/4204"}
        let(:links) {
          [
            {
              "url"=>"https://slack.com/message",
              "domain"=>"slack.com"
            },
            {
              "url"=> url,
              "domain"=>"github.com"
            }
          ]
        }
        it "returns a 200 status" do
          response = handler.call(lambda_event)

          expect(response.fetch("statusCode")).to eq(200)
        end

        context "and the link refers to a pull request" do
          let(:url) { "https://github.com/ExampleUser/example_repo/pull/4204"}
          it "captures the mention as a PR and message identifier" do
            handler.call(lambda_event)

            mentions_store = handler.mentions_store
            saved_mention = mentions_store.last_mention

            expect(saved_mention[:pr_id]).to eq("github.com/exampleuser/example_repo/pull/4204")
            expect(saved_mention[:mention_id]).to eq("CHANNEL200|1555820195.000400")
          end
        end
        context "and the link does not refer to a pull request" do
          let(:url) { "https://github.com/ExampleUser/example_repo/blob/85f396092b14c8/a.txt"}

          it "does not capture a mention" do
            handler.call(lambda_event)

            mentions_store = handler.mentions_store
            saved_mention = mentions_store.last_mention

            expect(saved_mention).to be_nil
          end
        end
      end

      context "containing no github links" do
        let(:links) {
          [
            {
              "url"=>"https://slack.com/message",
              "domain"=>"slack.com"
            }
          ]
        }

        it "returns a 200 status" do
          response = handler.call(lambda_event)

          expect(response.fetch("statusCode")).to eq(200)
        end

        it "does not capture a mention" do
          handler.call(lambda_event)

          mentions_store = handler.mentions_store
          saved_mention = mentions_store.last_mention

          expect(saved_mention).to be_nil
        end
      end

      context "containing more than one github link" do
        let(:links) {
          [
            {
              "url"=>"https://github.com/ExampleUser/example_repo/pull/4204",
              "domain"=>"github.com"
            },
            {
              "url"=>"https://github.com/ExampleUser/example_repo/pull/8888",
              "domain"=>"github.com"
            }
          ]
        }

        it "returns a 200 status" do
          response = handler.call(lambda_event)

          expect(response.fetch("statusCode")).to eq(200)
        end

        # We won't be able to react to an individual PR in the mention, so
        # it doesn't make sense to react at all.
        it "does not capture a mention" do
          handler.call(lambda_event)

          mentions_store = handler.mentions_store
          saved_mention = mentions_store.last_mention

          expect(saved_mention).to be_nil
        end

        context "but they are actually the same link" do
          let(:links) {
            [
              {
                "url"=>"https://github.com/ExampleUser/example_repo/pull/4204",
                "domain"=>"github.com"
              },
              {
                "url"=>"https://github.com/ExampleUser/example_repo/pull/4204",
                "domain"=>"github.com"
              },
            ]
          }

          it "captures the mention as a PR and message identifier" do
            handler.call(lambda_event)

            mentions_store = handler.mentions_store
            saved_mention = mentions_store.last_mention

            expect(saved_mention).to_not be_nil
            expect(saved_mention[:pr_id]).to eq("github.com/exampleuser/example_repo/pull/4204")
            expect(saved_mention[:mention_id]).to eq("CHANNEL200|1555820195.000400")
          end
        end
      end
    end
  end

end
