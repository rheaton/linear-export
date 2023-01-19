require 'bundler'
Bundler.require

require "graphql/client"
require "graphql/client/http"
require_relative 'fragments'

module Linear
  class Fetcher
    API = "https://api.linear.app/graphql"
    attr_reader :client, :http
    def initialize
      initialize_http
      initialize_schema
      initialize_client
    end

    def parse_query_string(query_string)
      client.parse query_string
    end

    # def dump_schema
    #   GraphQL::Client.dump_schema(http, "linear_schema.json")
    # end

    def self.set_token(token)
      @token = token
    end

    def self.token
      @token
    end

    private

    def initialize_http
      @http = GraphQL::Client::HTTP.new(API) do
        def headers(context)
          {
          "Content-Type": "application/json",
          "Authorization": "Bearer #{Linear::Fetcher.token}"		
          }
        end
      end
    end

    def initialize_schema
      @schema = GraphQL::Client.load_schema http
    end

    def initialize_client
      @client = GraphQL::Client.new(schema: schema, execute: http)
    end

    attr_reader :token, :schema
  end
end
