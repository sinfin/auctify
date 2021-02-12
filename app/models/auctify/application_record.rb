# frozen_string_literal: true

module Auctify
  class ApplicationRecord < ActiveRecord::Base
    self.abstract_class = true
  end
end
