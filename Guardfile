# frozen_string_literal: true

guard :rubocop, cli: ["--auto-correct-all"] do
  watch(/^(app|config|db|test)\/.+\.rb$/)
  watch(/^lib\/.+\.(rb|rake)$/)

  watch(%r{(?:.+/)?\.rubocop(?:_todo)?\.yml$}) { |m| File.dirname(m[0]) }
end

guard :slimlint, notify_on: :failure do
  watch(/^(app|test)\/.+(\.slim)$/)
end
