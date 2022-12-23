require './lib/fetcher'
require './lib/queries'
require 'pry'

token = IO.read("#{Dir.home}/.linear").strip
Linear::Fetcher.set_token(token)
fetcher = Linear::Fetcher.new

UserFragment = fetcher.parse_query_string(Linear::Fragments::USER)
# ugh https://github.com/github/graphql-client/blob/master/guides/dynamic-query-error.md
Query = fetcher.parse_query_string Linear::Queries::ISSUE

result = fetcher.client.query(Query, variables: {issueId: "f2123bce-dded-46b5-9825-ccb00ea41e08"})
# {
#   "issueId": "f2123bce-dded-46b5-9825-ccb00ea41e08",
#   "teamId": "00639a55-bb50-4cff-b890-7e23ced0830e",
#   "projectId": null
# }

binding.pry

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
