# frozen_string_literal: true

module Approval
  module PrimaryKey
    SORT_KEY = "approved"

    def self.call(pr_id)
      {
        "part_key": pr_id,
        "sort_key": SORT_KEY
      }
    end
  end
end
