# frozen_string_literal: true

module Auctify
  class TestUser
    attr_reader :name, :id

    def initialize(name:, id: nil)
      @name = name
      @id = id || rand(1000)
    end
  end
end

def new_user(name: nil)
  id = rand(1000)
  Auctify::TestUser.new(name: "T user #{id}", id: id)
end
