# frozen_string_literal: true

require "logger"
require "pull_request_identifier"
require "mark_pr_approved"

module Github
  class PullRequestApproved
    dependency :logger, Logger
    dependency :dynamodb_client, Aws::DynamoDB::Client
    dependency :invoke_mark_pr_approved, MarkPrApproved::Invoke

    attr_accessor :table_name

    def self.call(payload)
      build.call(payload)
    end

    def self.build
      new.tap do |instance|
        DynamodbClient.configure(instance)
        Logger.configure(instance)
        Settings.configure("prapproved", instance)
        MarkPrApproved::Invoke.configure(instance)
      end
    end

    def self.configure(other)
      other.pull_request_approved = build
    end

    def call(payload)
      pr_url = payload["pull_request"]["html_url"]
      pr_id = PullRequestIdentifier.(pr_url)

      item = {
        pr_id: pr_id,
        approved_at: Time.now.to_i # needs to be integer. add assertion
      }

      logger << "Save approval: #{item} to #{table_name}"
      dynamodb_client.put_item(table_name: table_name, item: item)

      invoke_mark_pr_approved.(pr_id)
    rescue => e
      logger << "ERROR: #{e.inspect}\n#{e.backtrace}"
    end

    class Substitute
      def self.build
        new
      end

      attr_reader :invocations

      def initialize
        @invocations = []
      end

      def call(payload)
        invocations << payload
      end

      def last_invocation
        invocations.last
      end
    end
  end
end
