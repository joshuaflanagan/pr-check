# frozen_string_literal: true

require "dependency"
# define 'dependency' macro on Object
Dependency.activate

require "logger"
require "dynamodb_client"
require "mentions_store"

DynamodbClient.init
