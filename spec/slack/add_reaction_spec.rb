require "spec_helper"
require "slack/add_reaction"

RSpec.describe "Slack::AddReaction" do
  subject(:add_reaction) { Slack::AddReaction.new }

  it "sends an HTTP POST to the Slack reactions.add endpoint" do
    add_reaction.call(channel: "1234", timestamp: "100.001", reaction: "yes")

    http_request = add_reaction.http.last_request

    expect(http_request.verb).to eq(:post)
    expect(http_request.uri).to eq("https://slack.com/api/reactions.add")
  end

  it "send the channel, message timestamp, and reaction name in a JSON paylaod" do
    add_reaction.call(channel: "1234", timestamp: "100.001", reaction: "yes")

    payload = add_reaction.http.last_request.payload

    expect(payload["channel"]).to eq("1234")
    expect(payload["timestamp"]).to eq("100.001")
    expect(payload["name"]).to eq("yes")
  end
end
