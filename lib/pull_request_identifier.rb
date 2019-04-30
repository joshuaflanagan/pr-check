# frozen_string_literal: true

class PullRequestIdentifier
  def self.call(url)
    build.call(url)
  end

  def self.build
    new
  end

  def call(url)
    _protocol, pr_id = url.split("://", 2)
    pr_id
  end
end
