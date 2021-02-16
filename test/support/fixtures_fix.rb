# frozen_string_literal: true

# Auctify::Sale::Base if STI and have polymorphic association
class ActiveSupport::TestCase
  set_fixture_class "auctify/sales" => Auctify::Sale::Base
end

class ActionDispatch::IntegrationTest
  set_fixture_class "auctify/sales" => Auctify::Sale::Base
end
