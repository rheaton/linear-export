require 'bundler'
Bundler.require

require "graphql/client"
require "graphql/client/http"
require_relative 'fragments'
require_relative 'custom_network_adapter'

module Linear
  class Fetcher
    API = "https://api.linear.app/graphql"
    attr_reader :client, :http, :token

    def initialize(token)
      @token = token
      initialize_http(@token)
      initialize_schema
      initialize_client
    end

    def update_token(token)
      return if token == @token
      @token = token
      initialize_http(@token)
      initialize_client
    end

    def parse_query_string(query_string)
      client.parse query_string
    end

    # def dump_schema
    #   GraphQL::Client.dump_schema(http, "linear_schema.json")
    # end

    def response_metadata
      @http.response_metadata
    end

    private

    def initialize_http(token)
      @http = CustomNetworkAdapter.new(API) do
        def headers(context)
          {
          "Content-Type": "application/json",
          "Authorization": "Bearer #{current_token}"
          }
        end
      end
      puts "Initializing new CNA object id: #{@http.object_id}"
      @http.current_token = token
      @http
    end

    def initialize_schema
      @schema = GraphQL::Client.load_schema http
    end

    def initialize_client
      @client = GraphQL::Client.new(schema: schema, execute: http)
    end

    attr_reader :schema
  end
end
