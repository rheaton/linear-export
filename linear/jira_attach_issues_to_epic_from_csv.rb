require_relative 'lib/jira'
require 'optparse'
require 'csv'

options = {
  file: nil,
  jira_project_key: nil,
}

OptionParser.new do |opts|
  opts.on('--mapping-file blahblah.csv', 'mapping file') do |i|
    options[:file] = i
  end
  opts.on('--jira-project-key MYPRJ', 'Jira Project Key aka ticket prefix') do |i|
    options[:jira_project_key] = i
  end

  opts.on('-h', '--help', 'Prints this help') do
    puts opts
    exit
  end
end.parse!

client = Jira::EpicClient.new(ENV['JIRA_CREDS'], 'https://workramp.atlassian.net/issues')

epics_map = client.get_all_epics_in_project_by_name(options[:jira_project_key])

# Open the CSV file
CSV.foreach(options[:file], headers: true) do |row|
  # Convert each row to a hash, using the header row as the keys
  row_hash = row.to_hash
  epic_name = row_hash['Epic Name']
  issues_to_attach = row_hash['Issue Keys'].split("\0")
  epic_key = epics_map[epic_name]
  if !epic_key
    puts "Could not find epic :( #{epic_name}"
  elsif issues_to_attach.any? {|issue| issue.start_with?(options[:jira_project_key])}
    puts "Going to try to attach these keys: #{issues_to_attach.join('; ')} to epic #{epic_name}"
    client.attach_to_epic(epic_key: epic_key, issue_keys: issues_to_attach)
  else
    puts "I don't see a point in doing this because all attached issues are in foreign projects #{epic_name}"
  end
end


response = client.attach_to_epic(epic_key: 'TSTP-4', issue_keys: %w(TSTP-54 TSTP-53))
puts response