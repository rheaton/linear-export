module Linear
  module Fragments
    USER = <<-'GRAPHQL'
    fragment on User {
      id, active, guest, email
    }
    GRAPHQL
  end
end