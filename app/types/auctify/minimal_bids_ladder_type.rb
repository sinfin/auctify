# frozen_string_literal: true

module Auctify
  # in ruby/rails we expecting default format as hash with ranges { (0...1_000) => 200, (1_000..) => 500 }
  # but acceppting (in setter) also hash with numbers or strings
  # in DB we store JSON with minimal prices casted to nice strings : { "0" => 200, "1_000" => 500 }
  class MinimalBidsLadderType < ActiveRecord::Type::Value
    def type
      :jsonb
    end

    def cast(value) # setter
      # hash is expected as value
      value = JSON.parse(value) if value.is_a?(String)
      case value.keys.first
      when Range  # { (0...1_000) => 200, (1_000..) => 500 }
        cast_from_ranges(value)
      when String # { "0" => 200, "1_000" => 500 }
        cast_from_min_strings(value)
      when Numeric # { 0 => 200, 1000 => 500 }
        cast_from_min_numbers(value)
      else
        if value.blank?
          {}
        else
          raise "Uncovered ladder key type `#{value.keys.first}`"
        end
      end
    end

    def deserialize(db_value) # getter, from db data to ruby raw object
      return {} if db_value.blank?

      cast(ActiveSupport::JSON.decode(db_value))
    end

    def serialize(value) # modifier to store in db
      # value should be Hash with ranges as keys
      result = {}
      value.each_pair do |k_range, v|
        min_price_string = ActiveSupport::NumberHelper.number_to_delimited(k_range.first, delimiter: "_")
        result[min_price_string] = v
      end

      ActiveSupport::JSON.encode(result)
    end

    private
      def cast_from_ranges(hash)
        hash # desired format
      end

      def cast_from_min_strings(hash)
        result = {}
        hash.each_pair { |k, v| result[k.to_i] = v }

        cast_from_min_numbers(result)
      end

      def  cast_from_min_numbers(hash)
        previous_step = nil

        result = hash.to_a.sort.each_with_object({}) do |step, rslt|
          unless previous_step.nil?
            rslt[Range.new(previous_step.first, step.first, true)] = previous_step.last
          end
          previous_step = step
        end
        result[Range.new(previous_step.first, nil, false)] = previous_step.last

        result
      end
  end
end
