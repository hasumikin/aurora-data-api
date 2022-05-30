# frozen_string_literal: true

class ::User < AuroraDataApi::Model
  schema do
    col :name, String
    col :height, Integer
    col :temperature, Float
    timestamp
  end
end

class ::Entry < AuroraDataApi::Model
  table :entries
  schema do
    col :title, String
    col :body, String
    col :user, :User
    timestamp
  end
end

UserDepot = AuroraDataApi::Depot[User] do
end

EntryDepot = AuroraDataApi::Depot[Entry] do
end
