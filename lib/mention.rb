# frozen_string_literal: true

module Mention
  module PrimaryKey
    PREFIX = "mention:"

    def self.call(pr_id, mention_id)
      {
        part_key: pr_id,
        sort_key: PREFIX + mention_id,
      }
    end
  end
end
