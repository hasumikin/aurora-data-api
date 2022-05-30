# frozen_string_literal: true

require_relative '../models/entry'

EntryDepot = AuroraDataApi::Depot[Entry] do
end
