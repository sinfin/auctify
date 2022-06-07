# frozen_string_literal: true

require "test_helper"
require "minitest/mock"

module MethodInvokingMatchersHelper
  private
    def expect_method_called_on(object:, method:, args:, return_value: :not_passed, &block)
      if return_value == :not_passed
        return_value = (object.class.name == "Class" ? "call to #{object}.#{method}" : "call to #{object.class}##{method}")
      end

      mock_of_method = Minitest::Mock.new
      mock_of_method.expect :call, return_value, args

      object.stub(method, mock_of_method, &block)
      mock_of_method.verify
    end

    def expect_no_method_called_on(obj, method, &block)
      obj.stub(method, ->(*args) { raise "Unexpected call of :#{method} on #{obj.class.name}#{obj.to_json}" }, &block)
    end
end
