# frozen_string_literal: true

namespace :test do
  Rake::TestTask.new(:dummy) do |t|
    t.libs << "test"
    t.pattern = "test/dummy/test/**/*_test.rb"
    t.verbose = true
  end
end
# Rake::Task[:test].enhance ["test:dummy"]
