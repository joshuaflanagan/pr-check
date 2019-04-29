# frozen_string_literal: true

require "aws-sdk-lambda"

class LambdaClient
  def self.init(opts={})
    @aws_client = Aws::Lambda::Client.new(opts)
  end

  def self.aws_client
    @aws_client || raise("Must call .init before accessing .aws_client")
  end

  def self.configure(other)
    other.lambda_client = aws_client
  end
end
