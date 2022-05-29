# frozen_string_literal: true

require "test_helper"

class AuroraDataApiTest < Test::Unit::TestCase
  test "VERSION" do
    assert do
      ::AuroraDataApi.const_defined?(:VERSION)
    end
  end
end
