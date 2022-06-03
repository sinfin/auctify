# frozen_string_literal: true

class MonitoringRecord < ApplicationRecord
  scope :ordered, -> { order(created_at: :desc) }

  def self.download_current(connection_config)
  end
end
