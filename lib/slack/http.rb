# frozen_string_literal: true

require "http"

module Slack
  class Http
    attr_accessor :slack_token

    def self.configure(other)
      other.http = build
    end

    def self.build
      new.tap do |instance|
        Settings.configure("slack", instance)
      end
    end

    def call(verb, uri, payload: nil)
      response = HTTP.headers("Authorization" => "Bearer #{slack_token}").
        request(verb, uri, json: payload)
      unless response.status.ok?
        raise Error.new(response)
      end
    end

    class Error < StandardError
      attr_reader :response

      def initialize(response)
        @response = response
        super("#{response.code} - #{response.body}")
      end
    end

    class Substitute
      def self.build
        new
      end

      Request = Struct.new(:verb, :uri, :payload)

      attr_reader :requests

      def initialize
        @requests = []
      end

      def call(verb, uri, payload: nil)
        requests << Request.new(verb, uri, payload)
      end

      def last_request
        requests.last
      end
    end
  end
end
