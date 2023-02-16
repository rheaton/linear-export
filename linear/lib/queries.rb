module Linear
  # https://studio.apollographql.com/public/Linear-API/explorer
  # https://studio.apollographql.com/public/Linear-API/explorer?explorerURLState=N4IgJg9gxgrgtgUwHYBcQC4QEcYIE4CeABAAp4QBWCUKAzgIq6FHAA6SRRADuVTbS3adOSCGAQC2HYZwCWYADREkAQ0RKhMoigRrJmrcrETB0w3MXK1CA1oC%2BtmVxUBzBAEkkAMwinzwgAsVWgA5BAAPFBJXGzN7RyIHOKSnGM8fPy0g0IiomNsUxPYknHxiABVdOAYmYilOHT1MkWN9OIslVUQC22c3dN96rOCwyOi3HukkpPZS5kq1RjKACgASRrh3MHQiAGUUPFkkFwBCAEpMjeX5HfWqrYuhjqtuuNlaWlw2w1Fxb-N5MgULIvLJ8Ep5EoeAgAG6yCAwWhbIEgsF4WgJQqcQrTdh47x4VyIVBEACqtHwADFCS5iSgiBAOOT8JlIUQVDRZDCEEoXF8UEoEHAVLIADbFfFzYjuD64JaENbvT4ebZ7A5HU6PTRK3DXVWrHUqrVvcSoVHgohs6FwhFI03A0H4DFxYEoUU8oh-KCHLjAxm2ABGhKQUACIWsgtowOFOihhwghxQBDj8MTBAAMioAwhxXEwLgACIqWNEb26HRgACCAqIMC4YGLCCrNYOwQCTdsG2awjZXViMixpbw5YT3c4ADpJ8y8NSiUDJjIo42xy8PVwILRZH6kAvhKKszn-jJfiYnlpe9ZMbvOMWUByAnSj8IT0%2BZDA8KKIZZXe6lJ8Az%2B-bmGWxajmehiTuO06zrS87tMIg7YtepYQHAj4ri%2BK6cIiLLgVokHQTSdIJEh8HPAGYjJkO5ZNtWgpgFutEoCR3AqMOJJ4TI8gsYhRTJL0bFAiubKAmajp4MhoZimA7EYa0WGWpYokOmiV78XEPCUNQ9J4X2u64juSAgHYQA&variant=current
  module Queries
    TEAMS = <<-'GRAPHQL'
    query {
      teams {
        nodes {
          id, name
        }
        pageInfo {
          hasNextPage, endCursor
        }
      }
    }
    GRAPHQL

    PROJECTS = <<-'GRAPHQL'
    query($first: Int!) {
      projects(first: $first) {
        nodes {
          id, name, 
          teams {
            nodes {
              id, name
            }
            pageInfo {
              hasNextPage, endCursor
            }
          }
        }
        pageInfo {
          hasNextPage, endCursor
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
            hasNextPage, endCursor
          }
        }
      }
    }
    GRAPHQL

    ISSUE = <<-'GRAPHQL'
    query($issueId: String!) {
      issue(id: $issueId) {
      priority,
      description
      status: state {
        name
      }
      creator {
        ...UserFragment
      }
      assignee {
        ...UserFragment
      }
      labels {
        nodes {
          id, name
        }
      }
      identifier, id, previousIdentifiers
        title, 
        dueDate, createdAt, updatedAt, 
        team {
          id, name
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
        trashed, branchName, estimate, 
      }
    }
    GRAPHQL

    FIRSTISSUESOFPROJECT = <<-'GRAPHQL'
    query($name: String!, $first: Int!) {
      issues(filter: {team: {name: {eq: $name}}}, first: $first) {
        nodes {
          id, identifier
        }
        pageInfo {
          hasNextPage, endCursor
        }
      }
    }
    GRAPHQL

    ISSUESOFPROJECT = <<-'GRAPHQL'
    query($name: String!, $first: Int!, $after: String!) {
      issues(filter: {team: {name: {eq: $name}}}, first: $first, after: $after) {
        nodes {
          id, identifier
        }
        pageInfo {
          hasNextPage, endCursor
        }
      }
    }
    GRAPHQL

    COMMENTS = <<-'GRAPHQL'
    query($id: ID) {
      comments(first: 250, filter: {issue: {id: {eq: $id}}}) {
        nodes {
          body, createdAt
          issue { 
            id, identifier
          }
          user {
            email
          }
        }
      }
    }
    GRAPHQL

    FIRSTISSUESOFPROJECTCOMMENTS = <<-'GRAPHQL'
    query($name: String!, $first: Int!) {
      issues(filter: {team: {name: {eq: $name}}}, first: $first) {
        nodes {
          id, identifier
        comments(first: 100) {
          nodes {
            body, createdAt
            user {
              email
            }
          }
        }
        }
        pageInfo {
          hasNextPage, endCursor
        }
      }
    }
    GRAPHQL

    ISSUESOFPROJECTCOMMENTS = <<-'GRAPHQL'
    query($name: String!, $first: Int!, $after: String!) {
      issues(filter: {team: {name: {eq: $name}}}, first: $first, after: $after) {
        nodes {
          id, identifier
        comments(first: 100) {
          nodes {
            body, createdAt
            user {
              email
            }
          }
        }
        }
        pageInfo {
          hasNextPage, endCursor
        }
      }
    }
    GRAPHQL

    PROJECTS_IN_TEAM = <<-'GRAPHQL'
        query ($teamId: String!) {
          team(id: $teamId) {
            projects(first: 60) {
              nodes {
                name
                description
                targetDate
                completedAt
                description
                name
                createdAt
                creator {
                  email
                }
                state
                updatedAt
                issues(first: 50) {
                  nodes {
                    identifier
                    parent {
                      identifier
                    }
                  }
                }
              }
            }
          }
        }
GRAPHQL

    DUMMY = <<~'GRAPHQL'
      query ($first: Int) {
        emojis(first: 1) {
          nodes {
            name
          }
        }
      }
    GRAPHQL

    ISSUE_IDS_WITH_SUBTASK_IDS = <<~'GRAPHQL'
      query ($teamId: String!, $first: Int, $after: String) {
        team(id: $teamId) {
          issues(first: $first, after: $after ) {
            pageInfo {
              hasNextPage
              endCursor
            }
            nodes {
              identifier
              children {
                nodes {
                  identifier
                }
              }
            }
          }
        }
      }
    GRAPHQL
  end
end
