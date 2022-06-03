# frozen_string_literal: true

class User < AuroraDataApi::Model
  schema do
    col :name,             String
    col :internet_account, String
    col :banned,           ::AuroraDataApi::Type::Boolean, default: false
    timestamp
  end

  def twitter
    "https://twitter.com/#{internet_account}"
  end
end
