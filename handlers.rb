# frozen_string_literal: true

$LOAD_PATH.unshift(File.expand_path("lib", __dir__))
load "vendor/bundle/bundler/setup.rb"

require 'json'

def hello(event:, context:)
  { statusCode: 200, body: JSON.generate('Go Serverless v1.0! Your function executed successfully!') }
end
