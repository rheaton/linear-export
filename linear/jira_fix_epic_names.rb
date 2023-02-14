require_relative 'lib/jira'
require 'optparse'
require 'csv'

def trunc(str, max = 25)
  if str.length <= max
    return str
  else
    remove_chars = str.length - (max - 1)
    start_pos = (str.length - remove_chars) / 2
    end_pos = start_pos + remove_chars - 1
    return str[0..(start_pos-1)] + "…" + str[(end_pos+1)..-1]
  end
end

# PROJECTS = %w(PLAT1 ES2 INFRA)
PROJECTS = %w(ENG)

client = Jira::EpicClient.new(ENV['JIRA_CREDS'], 'https://workramp.atlassian.net/issues')

PROJECTS.each do |pkey|
  epics = client.get_all_epics_in_project_by_name("#{pkey} AND \"Epic Name\" is empty", result_type: :full)
  epics.each do |epic|
    next unless epic['customfield_10011'].nil?
    client.update_epic_name_field(epic['key'], trunc(epic['fields']['summary']))
  end
  sleep 2
end

