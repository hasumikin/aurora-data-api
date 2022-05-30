# frozen_string_literal: true

class Comment < AuroraDataApi::Model
  schema do
    col :user,  :User, table: :users, null: false
    col :entry, :Entry, table: :entries, null: false
    col :body,  String
    timestamp
  end
end
