# frozen_string_literal: true

class PullRequestIdentifier
  def self.call(url)
    build.call(url)
  end

  def self.build
    new
  end

  PR_ID_REGEX = /github\.com\/(.+?)\/(.+?)\/pull\/\d+/i
  def call(url)
    match = PR_ID_REGEX.match(url)
    if match
      match.to_s.downcase
    end
  end
end
