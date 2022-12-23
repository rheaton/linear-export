module Linear
  # https://studio.apollographql.com/public/Linear-API/explorer
  module Queries
    TEAMS = <<-'GRAPHQL'
    query {
      teams {
        nodes {
          id, name
        }
        pageInfo {
          hasNextPage
        }
      }
    }
    GRAPHQL

    PROJECTS = <<-'GRAPHQL'
    query {
      projects {
        nodes {
          id, name, 
          teams {
            nodes {
              id, name
            }
            pageInfo {
              hasNextPage
            }
          }
        }
        pageInfo {
          hasNextPage
        }
      }
    }
    GRAPHQL

    TEAM = <<-'GRAPHQL'
    query($teamId: String!) {
      team(id: $teamId) {
        id, name
        issues {
          nodes {
            identifier, id, previousIdentifiers
          }
          pageInfo {
            hasNextPage
          }
        }
      }
    }
    GRAPHQL

    ISSUE = <<-'GRAPHQL'
    query($issueId: String!) {
      issue(id: $issueId) {
        identifier, id, previousIdentifiers
        title, description
        branchName, estimate, priority, priorityLabel
        dueDate, createdAt, updatedAt, trashed
        team {
          id, name
        }
        creator {
          ...UserFragment
        }
        state {
          name, position
        }
        labels {
          nodes {
            id, name
          }
        }
        attachments {
          nodes {
            url, id, title, subtitle
            creator {
              ...UserFragment
            }
          }
        }
        comments {
          nodes {
            user {
              ...UserFragment
            }
            id, body, createdAt, editedAt
            parent {
              id
            }
          }
        }
        parent {
          id, identifier
        }
        children {
          nodes {
            id, identifier
          }
        }
        project {
          name
        }
      }
    }
    GRAPHQL
  end
end