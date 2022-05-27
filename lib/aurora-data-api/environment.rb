# frozen_string_literal: true

module AuroraDataApi
  class Environment

    # Resources about "OFFLINE":
    #  https://www.serverless.com/plugins/serverless-offline
    #  https://github.com/koxudaxi/local-data-api

    def self.offline?
      ENV["IS_OFFLINE"] == "true"
    end

    def self.offline_endpoint
      "http://local-data-api"
    end

    def self.database_name
      ENV['PGDATABASE'] || ENV['MYSQL_DATABASE']
    end

    def self.region
      ENV.fetch("AWS_DEFAULT_REGION", "ap-northeast-1")
    end

    def self.secret_arn
      if offline?
        "arn:aws:secretsmanager:us-east-1:123456789012:secret:dummy"
      else
        ENV['RDS_SECRET_ARN']
      end
    end

    def self.resource_arn
      if offline?
        "arn:aws:rds:us-east-1:123456789012:cluster:dummy"
      else
        ENV['RDS_RESOURCE_ARN']
      end
    end
  end
end
