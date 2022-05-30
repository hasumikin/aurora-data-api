# frozen_string_literal: true

require_relative '../models/user'

UserDepot = AuroraDataApi::Depot[User] do
end
