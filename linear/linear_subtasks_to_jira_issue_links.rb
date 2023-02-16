require_relative 'lib/fetcher'
require_relative 'lib/queries'
require_relative 'lib/limits_manager'
require_relative 'lib/jira'
require 'json'

LINEAR_TEAM_ID = 'd5471e3c-36ba-4b1a-97a2-d4eb9983c957' #Support
jira = Jira::EpicClient.new(ENV['JIRA_CREDS'], 'https://workramp.atlassian.net/issues')

BAD_TICKETS = %w(ES2-1274 ES2-1275 ES2-1276)

TOKENS_QUEUE = ENV.filter {|k, v| k.start_with? 'LINEAR_API_KEY'}.values.map(&:strip)
exit 1 unless TOKENS_QUEUE.length > 0
token = TOKENS_QUEUE[0]
puts "Found %d tokens!" % TOKENS_QUEUE.length
fetcher = Linear::Fetcher.new(token)
@limits_manager = LimitsManager.new(TOKENS_QUEUE)

GraphQLQuery = fetcher.parse_query_string Linear::Queries::ISSUE_IDS_WITH_SUBTASK_IDS
base_variables = {
  teamId: LINEAR_TEAM_ID
}
@links = []
hasNext = true
after = nil
first = 50
while (hasNext) do
  variables = base_variables.merge({
                                     first: first,
                                     after: after
                                   })
  result = fetcher.client.query(GraphQLQuery, variables: variables)
  @limits_manager.process(fetcher.token, fetcher.response_metadata)
  puts "X"
  g = result.data.to_h['team']['issues']
  pagination = g['pageInfo']
  issues = g['nodes']
  issues.each do |node|
    children_array = node['children']['nodes']
    next if children_array.length == 0
    this_issue = node['identifier']
    links = children_array.map {|ch| ch['identifier']}
    links.each do |link|
      print "."
      next if BAD_TICKETS.include?(link)
      print "!"
      @links.push([this_issue, link])
    end
    after = pagination['endCursor']
    hasNext = pagination['hasNextPage']
  end

end

@links.each do |links|
  first_ticket, second_ticket = links
  puts "[JIRA]"
  jira.create_issue_link(first_ticket, second_ticket)
  puts "Just did #{first_ticket}, check it out!"
  puts "..."
end



