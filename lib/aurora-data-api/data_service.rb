# frozen_string_literal: true

require "aws-sdk-rdsdataservice"
require_relative "environment"

module AuroraDataApi
  class DataService
    def initialize
      client_param = {region: Environment.region}
      if Environment.offline?
        offline_config_update
        client_param[:endpoint] = Environment.offline_endpoint
      end
      @client = Aws::RDSDataService::Client.new(client_param)
      @execute_params = {
        database: Environment.database_name,
        secret_arn: Environment.secret_arn,
        resource_arn: Environment.resource_arn,
        include_result_metadata: true
      }
    end

    def execute(hash, without_databalse = false)
      if without_databalse
        @client.execute_statement(
          hash.merge(@execute_params.reject { |k, _v| k == :database })
        )
      else
        @client.execute_statement(hash.merge(@execute_params))
      end
    end

    private def offline_config_update
      Aws.config.update({
        credentials: Aws::Credentials.new(
          "AWS_ACCESS_KEY_dummy",
          "AWS_SECRET_ACCESS_KEY_dummy"
        )
      })
    end
  end
end
