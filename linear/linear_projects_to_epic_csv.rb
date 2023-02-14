require 'optparse'
require_relative 'lib/fetcher'
require_relative 'lib/queries'
require_relative 'lib/limits_manager'

require_relative 'csv_utils'
require 'json'
require 'pry'

# Parse Options
options = {
  file: nil,
  output_path: nil,
  project_name: nil
}

# Helper Methods For Cleaning CSV

def missing?(val)
  val.nil? || val.strip == ''
end

def get_resolution(status)
  return "Won't Do" if status == "Canceled"
  return "Done" if status == "Done" || status == "Resolved"
  ""
end

def convert_markdown(text)
  text ||= ""
  text = text.to_s unless text.is_a? String
  Kramdown::Document.new(text).to_confluence
end

OptionParser.new do |opts|
  opts.on('--team TEAM_UUID', 'Team UUID from Linear') do |i|
    options[:team_id] = i
  end
  opts.on('--jira-project "My Project"', 'Jira Project Name') do |i|
    options[:jira_project] = i
  end
  opts.on('--jira-project-key MYPRJ', 'Jira Project Key aka ticket prefix') do |i|
    options[:jira_project_key] = i
  end

  opts.on('-h', '--help', 'Prints this help') do
    puts opts
    exit
  end
end.parse!

options[:output_path] = '%s/%s_Epics.csv' % [Dir.pwd, options[:jira_project]]
options[:attachables_output_path] = '%s/%s_Attachables.csv' % [Dir.pwd, options[:jira_project]]

PROJECT_STATUS_MAP = {
  'Planned' => 'Open',
  'Paused' => 'Work Definition Pending',
  'Completed' => 'Done',
  'Canceled' => 'Archive'
}.tap {|h| h.default_proc = proc{|_,status| status}}

raise OptionParser::MissingArgument if %i(team_id jira_project jira_project_key).any? {|k| options[k].nil? }

TOKENS_QUEUE = ENV.filter {|k, v| k.start_with? 'LINEAR_API_KEY'}.values.map(&:strip)
exit 1 unless TOKENS_QUEUE.length > 0
token = TOKENS_QUEUE[0]
puts "Found %d tokens!" % TOKENS_QUEUE.length
fetcher = Linear::Fetcher.new(token)

@limits_manager = LimitsManager.new(TOKENS_QUEUE)

ProjectsQuery = fetcher.parse_query_string Linear::Queries::PROJECTS_IN_TEAM
# TODO RESUME HERE. Need to get results, PASSING TEAM ID, and iterate. build a csv for epics
#
variables = {teamId: options[:team_id]}
result = fetcher.client.query(ProjectsQuery, variables: variables)

@limits_manager.process(fetcher.token, fetcher.response_metadata)

projects = result.data.to_h['team']['projects']['nodes']

issues_map = []

data = ::Common::CsvUtils.generate do |csv|
  csv << ([
    'Project Name',
    'Project Key',
    'Project Type',
    'Summary',
    'Description',
    'Status',
    'Due Date',
    'Reporter',
    'Assignee',
    'Type',
    'Date Created',
    'Date Resolved',
    'Resolution',
    'Label',
])
  projects.each do |project|
    ticket_list = project['issues']['nodes'].filter {|issue| issue['parent'].nil?}.map {|i| i['identifier']}
    issues_map.push([project['name'], ticket_list])
    due_date = missing?(project['targetDate']) ? '' :  Date.strptime(project['targetDate'], '%Y-%m-%d').strftime('%a %b %d %Y %H:%M:%S')
    resolved_date = missing?(project['completedAt']) ? '' : DateTime.iso8601(project['completedAt']).strftime('%a %b %d %Y %H:%M:%S')
    csv << ([
      options[:jira_project], #project_name
      options[:jira_project_key], #project_key
      'Software', #project_type
      project['name'], #summary
      convert_markdown("#{project['description']}".strip).strip, #description
      PROJECT_STATUS_MAP[project['state']], #status
      due_date, #Due Date
      project['creator']['email'], #reporter
      project['creator']['email'], #assignee
      'Epic', #type
      DateTime.iso8601(project['createdAt']).strftime('%a %b %d %Y %H:%M:%S'), #date_created
      resolved_date, #date_resolved
      get_resolution(project['state']), #resolution
      'ImportedFromLinear' #label
    ])
  end
end


File.write(options[:output_path], data)
puts "Wrote projects to #{options[:output_path]}"

data_attachables = ::Common::CsvUtils.generate do |csv|
  csv << ['Epic Name', 'Issue Keys']
  issues_map.each do |entry|
    epic_name, issue_keys = entry
    if issue_keys.any? {|issue| issue.start_with?("#{options[:jira_project_key]}-")}
      csv << [epic_name, issue_keys.join("\0")]
    else
      puts "Note: Not creating epic for project #{epic_name} which has no #{options[:jira_project_key]} issues"
    end
  end
end
File.write(options[:attachables_output_path], data_attachables)
puts "Wrote attachables to #{options[:attachables_output_path]}."
puts "After the Epic tickets have been created using Jira Import process, use this command to attach all projects to epics:"
puts '---'
puts '%% ruby linear/jira_attach_issues_to_epic_from_csv.rb --mapping-file "%s" --jira-project-key %s' % [
  options[:attachables_output_path].gsub("#{Dir.pwd}/", ''),
  options[:jira_project_key]
]
