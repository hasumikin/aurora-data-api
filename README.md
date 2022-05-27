# AuroraDataApi

A kind of ORM for Amazon Aurora Serverless v1.

Assuming you are using AWS Lambda as a backend, Aurora Serverless v1 (NOT v2) as a database, and Data API as an adapter.

PostgreSQL is the only target as of now.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'aurora-data-api'
```

And then execute:

    $ bundle install

Or install it yourself as:

    $ gem install aurora-data-api

## Usage

Let's say we're developing a blog that has three models:

- User: able to post an entry and to comment on any entry
- Entry: an article
- Comment: a comment on an entry

```ruby
class User < AuroraDataApi::Model
  schema do
    col :name,             String
    col :internet_account, String
  end

  def twitter
    "https://twitter.com/#{internet_account}"
  end
end

class Entry < AuroraDataApi::Model
  schema do
    col :user,  :User  # User.to_sym
    col :title, String
    col :body,  String
  end
end

class Comment < AuroraDataApi::Model
  schema do
    col :user,  :User  # User.to_sym
    col :entry, :Entry # Entry.to_sym
    col :body,  String
  end
end
```

```ruby
require_relative '../models/user'
UserDepot = AuroraDataApi::Depot[User] do
end

require_relative '../models/entry'
EntryDepot = AuroraDataApi::Depot[Entry] do
end

require_relative '../models/comment'
CommentDepot = AuroraDataApi::Depot[Comment] do
end
```

### Create a user

```ruby
user = User.new(name: "HASUMI Hitoshi", internet_account: "hasumikin")
user.id                 # => nil
UserDepot.create(user)  # => 1
user.id                 # => 1
```

### Update the user

```ruby
user.internet_account = "HASUMIKIN"
UserDepot.update(user)  # => true (false if failed)
user.internet_account   # => "HASUMIKIN"
```

### Delete the user

```ruby
UserDepot.delete(user)  # => true (false if failed)
user.id                 # => nil
```

### Find a user

```ruby
hasumikin = UserDepot.select(
  "internet_account = :internet_account",
  internet_account: "hasumikin"
).first
```

### Post an entry

```ruby
my_entry = Entry.new(
  user: hasumikin,
  title: "My first article",
  body: "Hey, this is an article about Ruby."
)
EntryDepot.create(my_entry)
```

### Update the entry

```ruby
my_entry.body = "Hey, this is an article about Ruby whick is a happy language!"
EntryDepot.update(my_entry)
```

### Delete the entry

```ruby
EntryDepot.delete(my_entry)
```

### Select comments

```ruby
comments = CommentDepot.select(
  "inner join entry on entry.id = comment.entry_id where entry.user_id = :user_id",
  user_id: hasumikin.id
)
comments.class                 # => Array
comments.first.class           # => Comment
comments.first.body            # => "I have a question, ..."
comments.first.entry.class     # => Entry
comments.first.entry.title     # => "My first article"
comments.first.entry.user.name # => "HASUMI Hitoshi"
```

As of the current version, the last call `comments.first.entry.user.name` will execute another query so it may cause an N+1 problem.

## Application structure

```sh
your_app
├── Gemfile        # It includes `gem 'aurora-data-api'`
├── app
│   ├── handlers  # You may have Lambda functions here
│   ├── models
│   │   ├── comment.rb
│   │   ├── entry.rb
│   │   └── user.rb
│   └── depots
│       ├── comment_depot.rb
│       ├── entry_depot.rb
│       └── user_depot.rb
├── db
│   └── shcema.sql
└── serverless.yml # aurora-data-api is perfect for Serverless Framework
```

aurora-data-api doesn't have a generator to initiate the structure.
Make it manually instead like:

```sh
mkdir -p app/models app/depots db
```

## Environment variables

The following variables should be defined:

```ruby
ENV['PGDATABASE']       # Database name
ENV['RDS_RESOURCE_ARN'] # Resource ARN of RDS Aurora Serverless
ENV['RDS_SECRET_ARN']   # Secret ARN that is stored in AWS Secrets Manager
```

RDS_SECRET_ARN has to be attached to an IAM role of the "application".

## Migration

The following command overwrites `db/schema.sql` (for only PostgreSQL) by aggregating `app/models/*.rb`

```sh
bundle exec aurora-data-api export
```

We recommend to use @k0kubun's sqldef to manage migration.

See [k0kubun/sqldef](https://github.com/k0kubun/sqldef)

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake test-unit` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/hasumikin/aurora-data-api. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/hasumikin/aurora-data-api/blob/master/CODE_OF_CONDUCT.md).

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the AuroraDataApi project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/hasumikin/aurora-data-api/blob/master/CODE_OF_CONDUCT.md).
