require "spec_helper"
require "github/event_received"

RSpec.describe "Receiving a Github webhook" do
  subject(:handler) { Github::EventReceived.new }
  let(:lambda_event) {
    # This is the hash built by API Gateway to invoke the Lambda
    {
      "headers" => github_headers,
      "body" => JSON.generate(github_payload)
    }
  }

  context "for a pull_request_review event" do
    let(:github_headers){
      {
        "X-GitHub-Event" => "pull_request_review"
      }
    }
    let(:github_payload){
      {
        "action" => "submitted",
        "review" => review,
        "pull_request" => {},
        "repository" => {},
        "sender" => {}
      }
    }
    let(:review){
      {
        "state" => "commented"
      }
    }
    it "returns 200" do
      response = handler.call(lambda_event)

      expect(response.fetch("statusCode")).to eq(200)
    end

    context "when the review is an approval" do
      let(:review){
        {
          "state" => "approved"
        }
      }

      it "invokes the pull_request_approved handler" do
        handler.call(lambda_event)

        invocation = handler.pull_request_approved.last_invocation
        expect(invocation).to_not be_nil
      end
    end

    context "when the review is not an approval" do
      let(:review){
        {
          "state" => "commented"
        }
      }
      it "does not invoke the pull_request_approved handler" do
        handler.call(lambda_event)

        invocation = handler.pull_request_approved.last_invocation
        expect(invocation).to be_nil
      end
    end
  end

  context "for an unhandled event" do
    let(:github_headers){
      {
        "X-GitHub-Event" => "pull_request"
      }
    }
    let(:github_payload){
      {
        "action" => "other",
        "number" => "10",
        "pull_request" => {},
        "repository" => {},
        "sender" => {}
      }
    }

    it "returns 200" do
      response = handler.call(lambda_event)

      expect(response.fetch("statusCode")).to eq(200)
    end
  end
end
