require 'graphql'
require 'graphql/client/http'

class CustomNetworkAdapter < GraphQL::Client::HTTP
  attr_accessor :response_metadata
  attr_accessor :current_token

  def execute(document:, operation_name: nil, variables: nil, context: nil)
    request = Net::HTTP::Post.new(uri.request_uri)

    request.basic_auth(uri.user, uri.password) if uri.user || uri.password

    request["Accept"] = "application/json"
    request["Content-Type"] = "application/json"
    headers(context).each { |name, value| request[name] = value }

    body = {}
    body["query"] = document.to_query_string
    body["variables"] = variables if variables.any?
    body["operationName"] = operation_name if operation_name
    request.body = JSON.generate(body)

    response = connection.request(request)
    @response_metadata = response
    case response
    when Net::HTTPOK, Net::HTTPBadRequest
      JSON.parse(response.body)
    else
      { "errors" => [{ "message" => "#{response.code} #{response.message}" }] }
    end

  end
end