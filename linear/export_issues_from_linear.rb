require_relative './lib/fetcher'
require_relative './lib/queries'
require 'json'
require 'pry'

token = IO.read("#{Dir.home}/.linear").strip
Linear::Fetcher.set_token(token)
fetcher = Linear::Fetcher.new

UserFragment = fetcher.parse_query_string(Linear::Fragments::USER)
Query = fetcher.parse_query_string Linear::Queries::ISSUESOFPROJECT
# ugh https://github.com/github/graphql-client/blob/master/guides/dynamic-query-error.md
# Query = fetcher.parse_query_string Linear::Queries::ISSUE
# Query = fetcher.parse_query_string Linear::Queries::PROJECTS
# Query = fetcher.parse_query_string Linear::Queries::TEAMS
# Query = fetcher.parse_query_string Linear::Queries::COMMENTS


# result = fetcher.client.query(Query, variables: {issueId: "f2123bce-dded-46b5-9825-ccb00ea41e08"})

hasNextPage = true
endCursor = nil
nodes = []
total_complexity = 0
result = nil


# while(hasNextPage) do 
1.times do 
  puts "fetching 20"
  # result = fetcher.client.query(Query, variables: {first: 250, after: endCursor})
  # result = fetcher.client.query(Query, variables: {issueId: "f2123bce-dded-46b5-9825-ccb00ea41e08"})
  # result = fetcher.client.query(Query, variables: {id: "a52a2565-5d8b-41fa-bacb-687ce398a283"})
  # result = fetcher.client.query(Query, variables: {issueIdentifier: "SUP-53"})
  result = fetcher.client.query(Query, variables: {name: "Support"})
  
  # new_nodes = result.original_hash["data"]["projects"]["nodes"]
  # nodes.concat new_nodes
  # hasNextPage = result.original_hash["data"]["projects"]["pageInfo"]["hasNextPage"]
  # endCursor = result.original_hash["data"]["projects"]["pageInfo"]["endCursor"]
  nodes = result.original_hash["data"]
end

# {
#   "issueId": "f2123bce-dded-46b5-9825-ccb00ea41e08",
#   "teamId": "00639a55-bb50-4cff-b890-7e23ced0830e",
#   "projectId": null
# }

binding.pry

File.open("/tmp/comments.json","w") do |f|
  f.write(JSON.pretty_generate(nodes))
end




# Inline attachments do not require any 
#  auth headers to be fetched, but will need to have a bit of markdown parsing 
#  to get the filename, e.g.
# [Screenshot 2022-12-20 at 4.42.29 PM.png](https://uploads.linear.app/c2fe5267-b759-43e1-ae70-0e8b246e16f8/6da64117-d72b-4a5e-b864-096680c5150c/353e4330-f31c-4725-b649-ff73abab8cca)

# References to other Linear issues:
#  links to other Linear issues are also in the form noted above and will
#  need to be parsed out if we want to see the links, e.g.
# [https://linear.app/workramp/issue/ES1-381/admin-console-user-able-to-edit-go1-path-after-restoring-it](https://linear.app/workramp/issue/ES1-381/admin-console-user-able-to-edit-go1-path-after-restoring-it)

# Not sure if Jira will keep references to users in comments, e.g. 
# @jtully
