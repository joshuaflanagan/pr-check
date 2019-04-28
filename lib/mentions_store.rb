# frozen_string_literal: true

class MentionsStore
  dependency :dynamodb_client, Aws::DynamoDB::Client
  attr_accessor :table_name
  attr_accessor :ttl

  def self.configure(other)
    other.mentions_store = build
  end

  def self.build
    new.tap do |instance|
      Settings.configure("mentions", instance)
      DynamodbClient.configure(instance)
    end
  end

  def save(pr_id:, mention_id:)
    item = {
      pr_id: pr_id,
      mention_id: mention_id,
      expires_at: (Time.now.to_i + Integer(ttl))
    }
    dynamodb_client.put_item(table_name: table_name, item: item)
  end

  class Substitute
    attr_reader :mentions

    def initialize
      @mentions = []
    end

    def save(pr_id:, mention_id:)
      @mentions << {pr_id: pr_id, mention_id: mention_id}
    end

    def last_mention
      mentions.last
    end

    def self.build
      new
    end
  end
end
