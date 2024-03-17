# frozen_string_literal: true

source "https://rubygems.org"

git_source(:github) {|repo_name| "https://github.com/#{repo_name}" }

gem "aws-sdk-dynamodb"
gem "aws-sdk-lambda"
gem "evt-dependency"
gem "http"
gem "rexml" # needed by aws-sdk, no longer included in Ruby 3.0

group :development do
  gem "debug"
  gem "rspec"
end
