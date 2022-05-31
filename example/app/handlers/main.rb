# frozen_string_literal: true

Dir.glob("/var/runtime/bundler/gems/**").each do |dir|
  $LOAD_PATH.unshift("#{dir}/lib/")
end

require "json"
require "aurora-data-api"
require_relative "../depots/user_depot"
require_relative "../depots/entry_depot"
require_relative "../depots/comment_depot"

def hello(event:, context:)
  {
    statusCode: 200,
    body: { message: "Hello" }.to_json
  }
end

def users(event:, context:)
  users = UserDepot.select("order by id limit 10")
  {
    statusCode: 200,
    body: { users: users.map(&:attributes) }.to_json
  }
end

def create_user(event:, context:)
  params = JSON.parse(event["body"])
  user = User.new(**params)
  UserDepot.insert(user)
  {
    statusCode: 201,
    body: { user: user.attributes }.to_json
  }
end

def count_entry(event:, context:)
  count = EntryDepot.count
  {
    statusCode: 200,
    body: { count: count }.to_json
  }
end

def entries(event:, context:)
  entries = EntryDepot.select(
    "inner join users on users.id = entries.user_id order by entries.id limit 10"
  )
  #
  # (Note) This also works but N+1 query happens:
  #   EntryDepot.select("order by id limit 10")
  #
  {
    statusCode: 200,
    body: { entries: entries.map(&:attributes) }.to_json
  }
end

def create_entry(event:, context:)
  params = JSON.parse(event["body"])
  entry = Entry.new(**params)
  EntryDepot.insert(entry)
  {
    statusCode: 201,
    body: { entry: entry.attributes }.to_json
  }
end

def delete_entry(event:, context:)
  entry_id = JSON.parse(event["body"])["entry_id"]
  entry = EntryDepot.select('where id = :id', id: entry_id)[0]
  EntryDepot.delete(entry)
end
