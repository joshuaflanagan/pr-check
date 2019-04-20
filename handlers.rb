# frozen_string_literal: true

$LOAD_PATH.unshift(File.expand_path("lib", __dir__))
load "vendor/bundle/bundler/setup.rb"

require "slack_event_received"

module Handlers
  def self.slack_event_received(event:, context:)
    SlackEventReceived.(event, context)
  end
end
