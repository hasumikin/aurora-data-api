# frozen_string_literal: true

class Entry < AuroraDataApi::Model
  table :entries
  schema do
    col :user,  :User, table: :users, null: false
    col :title, String
    col :body,  String
    timestamp
  end
end

