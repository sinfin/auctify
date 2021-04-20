# frozen_string_literal: true

module Auctify
  class ApplicationRecord < ActiveRecord::Base
    self.abstract_class = true
    self.table_name_prefix = "auctify_"
  end
end
