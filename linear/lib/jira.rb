require 'net/http'
require 'json'
require 'base64'

module Jira
  # https://docs.atlassian.com/jira-software/REST/7.2.3/#agile/1.0/epic-moveIssuesToEpic
  class EpicClient
    BATCH_SIZE_LIMIT = 50 # documented at above url
    def initialize(credentials, jira_url)
      @creds = credentials
      parsed_url = URI.parse(jira_url)
      @atlassian_host = parsed_url.host
    end

    #https://your-domain.atlassian.net/rest/api/3/search?jql=project=PROJECT-KEY AND type=Epic
    def get_all_epics_in_project_by_name(project_key, result_type: :index)
      query = URI.encode_www_form_component('project=%s AND type=Epic' % project_key)
      endpoint = 'https://%s/rest/api/3/search?jql=%s' % [@atlassian_host, query]
      raw_response = rest_response(Net::HTTP::Get, endpoint)
      resp = JSON.parse(raw_response.body)
      if result_type == :index
        resp['issues'].each_with_object({}) do |hash, result|
          result[hash['fields']['summary']] = hash['key']
        end
      else
        resp['issues']
      end
    end

    def update_epic_name_field(epic_key, epic_name)
      puts 'Will update epic name for %s -> %s' % [epic_key, epic_name]
      body = { 'fields' => { 'customfield_10011' => epic_name } }
      endpoint = 'https://%s/rest/api/3/issue/%s' % [@atlassian_host, epic_key]
      raw_response = rest_response(Net::HTTP::Put, endpoint, body: body.to_json)
      puts raw_response.body
    end

    def attach_to_epic(epic_key:, issue_keys:)
      body = { 'issues' => issue_keys }
      endpoint = 'https://%s/rest/agile/1.0/epic/%s/issue' % [@atlassian_host, epic_key]
      raw_response = rest_response(Net::HTTP::Post, endpoint, body: body.to_json)
      puts raw_response.body
    end

    def create_issue_link(the_good_issue, the_duplicate_issue)
      body = {
        'type' => {
          'name' => 'Duplicate', 'inward' => 'is duplicated by', 'outward' => 'duplicates'
        },
        'inwardIssue' => {
          'key' => the_duplicate_issue
        },
        'outwardIssue' => {
          'key' => the_good_issue
        }
      }
      endpoint = 'https://%s/rest/api/3/issueLink' % [@atlassian_host]
      raw_response = rest_response(Net::HTTP::Post, endpoint, body: body.to_json)
      puts raw_response.body
    end

    # method should be Net::HTTP::Get, Net::HTTP::Post, etc.
    def rest_response(method, uri, body: nil)
      uri_parsed = URI.parse(uri)

      request = method.new(uri_parsed)
      request['Authorization'] = "Basic #{Base64.strict_encode64(@creds)}"
      request['Accept'] = 'application/json'
      unless body.nil?
        request.body = body
        request['Content-Type'] = 'application/json'
      end
      Net::HTTP.start(uri_parsed.host, uri_parsed.port, use_ssl: true) do |http|
        http.request(request)
      end
    end

  end
end