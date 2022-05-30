# frozen_string_literal: true

class User < AuroraDataApi::Model
  schema do
    col :name,             String
    col :internet_account, String
    timestamp
  end

  def twitter
    "https://twitter.com/#{internet_account}"
  end
end
