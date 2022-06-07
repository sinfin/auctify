# frozen_string_literal: true

require "yabeda/prometheus"

Yabeda.configure do
  group :auctify do
   gauge :t_gauge, comment: "Test gauge", tags: [:gtag]
   histogram :t_histogram, comment: "Test histogram", tags: [:htag], buckets: [1, 5, 10]
   counter :db_whistles_blows_total, comment: "A counter of whistles blown", tags: [:kind, :db_server]
 end

  collect do # when /metrics is displayed
    # main_app.t_gauge.set({}, rand(10))
  end
end
