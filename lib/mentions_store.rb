# frozen_string_literal: true

class MentionsStore
  def self.configure(instance)
    instance.mentions_store = build
  end

  def self.build
    new
  end

  def save(pr_id:, mention_id:)

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
