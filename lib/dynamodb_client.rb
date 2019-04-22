# frozen_string_literal: true

require "aws-sdk-dynamodb"

class DynamodbClient
  def self.init(opts={})
    @aws_client = Aws::DynamoDB::Client.new(opts)
  end

  def self.aws_client
    @aws_client || raise("Must call .init before accessing .aws_client")
  end

  def self.configure(other)
    other.dynamodb_client = aws_client
  end
end
