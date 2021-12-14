# frozen_string_literal: true

require "custom_logger"
require "settings"
require "slack/add_reaction"
require "mention"

class MarkPrApproved
  dependency :logger, CustomLogger
  dependency :dynamodb_client, Aws::DynamoDB::Client
  attr_accessor :reaction, :table

  def self.call(event, context)
    build.call(event)
  end

  def self.build
    new.tap do |instance|
      DynamodbClient.configure(instance)
      CustomLogger.configure(instance)
      Settings.configure("mark", instance)
    end
  end

  def call(event)
    logger << "EVENT: #{event.inspect}"
    body = JSON.parse(event["body"])
    pr_id = body.fetch("pr_id")

    logger << "Checking for approvals of #{pr_id} in #{table}"
    # See if the PR has been approved yet
    result = dynamodb_client.get_item({
      consistent_read: true,
      table_name: table,
      key: Approval::PrimaryKey.(pr_id)
    })
    unless result.item
      logger << "No approvals found"
      return return_value
    end

    # The PR was approved, find all messages that mentioned it
    logger << "Checking for mentions of #{pr_id} in #{table}"
    #TODO: filter to mentions that have not been updated
    result = dynamodb_client.query({
      table_name: table,
      consistent_read: true,
      key_condition_expression: "part_key=:pr AND begins_with(sort_key, :prefix)",
      expression_attribute_values: {
        ":pr"=> pr_id,
        ":prefix" => Mention::PrimaryKey::PREFIX
      }
    })
    logger << "Found #{result.items.length} mentions"

    result.items.each do |mention|
      mention_id = mention["sort_key"][Mention::PrimaryKey::PREFIX.length..-1]
      channel, timestamp = mention_id.split("|", 2)
      logger << "Adding reaction to #{channel} - #{timestamp}"
      response = Slack::AddReaction.(channel: channel, timestamp: timestamp, reaction: reaction)
      logger << "SLACK RESPONSE: #{response.status} - #{response.body}"
      #TODO: if successful, mark the mention as having a reaction
    rescue => e
      logger << "Error adding reaction to #{channel} - #{timestamp}: #{e.inspect}\n#{e.backtrace}"
    end

    return_value
  rescue => e
    logger << "ERROR: #{e.inspect}\n#{e.backtrace}"
  end

  def return_value
    {
      "statusCode" => 200
    }
  end

  class Invoke
    dependency :logger, CustomLogger
    dependency :lambda_client, Aws::Lambda::Client
    attr_accessor :function_name

    def self.call(pr_id)
      build.call(pr_id)
    end

    def self.build
      new.tap do |instance|
        CustomLogger.configure(instance)
        LambdaClient.configure(instance)
        Settings.configure("markpr", instance)
      end
    end

    def self.configure(other)
      other.invoke_mark_pr_approved = build
    end

    def call(pr_id)
      payload = {"pr_id" => pr_id}
      # Since we can invoke via HTTP as well, need to use same 'event' shape
      simulated_api_gateway_event = {
        "body" => JSON.generate(payload)
      }

      # Must invoke lambda with a string
      lambda_payload = JSON.generate(simulated_api_gateway_event)
      logger << "Invoking #{function_name} with #{lambda_payload}"

      result = lambda_client.invoke({
        function_name: function_name,
        invocation_type: "Event", # async
        payload: lambda_payload
      })

      logger << "Invocation result #{result.inspect}"
    end
  end
end
