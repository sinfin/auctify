# frozen_string_literal: true

# Base (surprise!) for Auctify services.
# Ascendants shoudl implement own methods `initialize` and `build_result`(which assigns to `@result`).
# In succesfull flow, call `srv = SomeService.call(*args)`
#   will return itself with result accessible by `srv.result`, errors by`srv.errors` and `srv.success? => true`
# In failed call (calling `fail!` when building result),
#   there can be still some result, even errors and `srv.success? => false` (or `srv.failed? => true`)
# Failing and errors are independent!
# Errors are like ActiveRecord errors, use `errors.add(:key, "message)`
# You can pass some information through `srv.flashes` hash

module Auctify
  class ServiceErrors < Hash
    def add(key, value, _opts = {})
      self[key] ||= []
      self[key] << value
      self[key].uniq!
    end

    def add_from_hash(errors_hash)
      errors_hash.each do |key, values|
        values.each { |value| add key, value }
      end
    end

    def full_messages
      f_msgs = []
      each_one { |field, message| f_msgs << "#{field}: #{message}" }
      f_msgs
    end

    def each_one
      each_pair do |field, messages|
        messages.each { |message| yield field, message }
      end
    end
  end

  class ServiceBase
    attr_reader :result, :errors, :flashes

    def self.call(*args, **keyword_args)
      if args.blank?
        new(**keyword_args).call
      elsif keyword_args.blank?
        new(*args).call
      else
        new(*args, **keyword_args).call
      end
    end

    def call
      build_result
      self # always returnning service itself, to get to `errors`, `result`
    end

    def initialize
      @result = nil
      @failed = false
      @flashes = {}
      @errors = ServiceErrors.new
    end

    def fail!
      @failed = true
    end

    def success?
      !failure?
    end

    def failure?
      @failed
    end
    alias failed? failure?
  end
end
