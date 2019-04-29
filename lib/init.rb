# frozen_string_literal: true

require "dependency"
# define 'dependency' macro on Object
Dependency.activate

require "logger"
require "settings"
require "dynamodb_client"
require "lambda_client"
require "mentions_store"

DynamodbClient.init
LambdaClient.init
Settings.init(ENV)
