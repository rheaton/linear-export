require 'optparse'
require_relative './lib/fetcher'
require_relative './lib/queries'
require 'json'
require 'pry'

# Parse Options
options = {
  file: nil,
  output_path: nil,
  project_name: nil
}

OptionParser.new do |opts|
  opts.on('--file PATH_TO_FILE', 'CSV file') do |file|
    options[:file] = file
  end

  opts.on('--output PATH_TO_OUTPUT_FILE', 'CSV file') do |output_file|
    options[:output_path] = output_file
  end

  opts.on('--project PROJECT_NAME', 'Project Name') do |project_name|
    options[:project_name] = project_name
  end

  opts.on('-h', '--help', 'Prints this help') do
    puts opts
    exit
  end
end.parse!

# Validate Options
raise OptionParser::MissingArgument if options[:file].nil?
raise OptionParser::MissingArgument if options[:output_path].nil?
raise OptionParser::MissingArgument if options[:project_name].nil?

# Fetch all issue ids and identifiers for given project
token = IO.read("#{Dir.pwd}/.linear").strip
Linear::Fetcher.set_token(token)
fetcher = Linear::Fetcher.new

UserFragment = fetcher.parse_query_string(Linear::Fragments::USER)
FirstIssueQuery = fetcher.parse_query_string Linear::Queries::FIRSTISSUESOFPROJECT
IssueQuery = fetcher.parse_query_string Linear::Queries::ISSUESOFPROJECT
CommentsQuery = fetcher.parse_query_string Linear::Queries::COMMENTS

hasNextPage = true
endCursor = nil
nodes = []
result = nil

project_name = options[:project_name].split("9").join(" ")

puts "fetching first 250 issues"
result = fetcher.client.query(FirstIssueQuery, variables: {name: project_name, first: 250})
issues = result.original_hash["data"]["issues"]
nodes = issues["nodes"]
hasNextPage = issues["pageInfo"]["hasNextPage"]
endCursor = issues["pageInfo"]["endCursor"]

while(hasNextPage) do 
  puts "fetching 250 issues"
  result = fetcher.client.query(IssueQuery, variables: {name: project_name, first: 250, after: endCursor})
  issues = result.original_hash["data"]["issues"]

  new_nodes = issues["nodes"]
  nodes.concat new_nodes
  hasNextPage = issues["pageInfo"]["hasNextPage"]
  endCursor = issues["pageInfo"]["endCursor"]
end

new_issues = {}

nodes.each do |issue|
  new_issues[issue["identifier"]] = issue["id"]
end

File.open("/tmp/linear-issues.json","w") do |f|
  f.write(JSON.pretty_generate(new_issues))
end

# Read from issues JSON file to data.
issues_file = File.read('/tmp/linear-issues.json')
issues = JSON.parse(issues_file)


# Read File, Clean Data, Write to Output File
data = ::Common::CsvUtils.generate do |csv|
  comments_array = Array((1..100))
  comments_array = comments_array.fill {|index| "Comments#{index + 1}" }

  csv << ([
    'Issue Id',
    'Issue Key',
    'Project Name',
    'Project Key',
    'Project Type',
    'Summary',
    'Description',
    'Status',
    'Priority',
    'Reporter',
    'Assignee',
    'Type',
    'Date Created',
    'Date Resolved',
    'Resolution',
    'Due Date',
    'Parent Id',
    'Label',
    'Flagged'
].concat(comments_array))

  csv_rows = SmarterCSV.process(options[:file])

  csv_rows.each do |info|
    puts "Working on issue #{info[:id]}"
    
    id = info[:id]
    key = id
    project_name = info[:team]
    project_key = id.partition('-').first
    project_type = 'software'
    summary = info[:title]
    description = convert_markdown(info[:description])
    status = translate_status(info[:status])
    priority = translate_priority(info[:priority])
    reporter = info[:creator]
    assignee = info[:assignee]
    type = translate_type(info[:labels], parent_id: !info[:parent_issue].nil?)
    date_created = clean_date(info[:created])
    date_resolved = clean_date(info[:completed])
    resolution = get_resolution(status)
    due_date = clean_date(info[:due_date])
    parent_id = info[:parent_issue]
    flagged = info[:status] == "Blocked" ? "Blocked" : ""

    label = "ImportedFromLinear"
    label += info[:status] == "Icebox" ? " Icebox" : ""
    parent_issue_id = info[:parent_issue]
    label += !parent_issue_id.nil? ? " sub-task-of-#{parent_issue_id.partition('-').first}" : ""
    
    # Run query to get comments
    sleep(27)
    query_result = fetcher.client.query(CommentsQuery, variables: {id: issues[id]})
    puts query_result.original_hash
    query_result = query_result.original_hash["data"]["comments"]["nodes"]
    parsed_comments_array = []
    query_result.each do |comment|
      parsed_comments_array << "#{parse_date(comment["createdAt"])};#{comment["user"]["email"]};#{convert_markdown(comment["body"])}"
    end

    csv << ([
      id,
      key,
      project_name,
      project_key,
      project_type,
      summary,
      description,
      status,
      priority,
      reporter,
      assignee,
      type,
      date_created,
      date_resolved,
      resolution,
      due_date,
      parent_id,
      label,
      flagged
    ].concat(parsed_comments_array))
  end
end

File.write(options[:output_path], data)
puts "Wrote to #{options[:output_path]}"


# Helper Methods For Cleaning CSV
BEGIN {
  STATUS_MAP = {
    "Epics" => "Epics",
    "In Progress" => "In Progress",
    "Backlog" => "Backlog",
    "Todo" => "Open",
    "Done" => "Done",
    "Canceled" => "Closed",
    "In Review" => "In Review",
    "Blocked" => "Open",
    "Triage" => "Backlog",
    "Need More Info" => "Backlog",
    "Deployed - Awaiting Task" => "Resolved",
    "Resolution Verified" => "Resolved",
    "Awaiting Deployment" => "Resolved",
    "QA Verified" => "Resolved",
    "Awaiting Engineering" => "Awaiting Engineering",
    "In QA" => "In QA",
    "PM Review" => "In Review",
    "Icebox" => "Backlog"
  }
  PRIORITY_MAP = {
    "Urgent" => "P0",
    "High" => "P1",
    "Medium" => "P2",
    "Low" => "P3",
    "No priority" => "P4"
  }
  TYPE_MAP = {
    "" => "Story",
    "type: bug" => "Bug",
    "type: feature" => "Story",
    "type:epic" => "Epic",
    "type: documentation" => "Task",
    "type:risk" => "Story",
    "type:ui-issue" => "Bug"
  }

  def translate_status(status)
    STATUS_MAP[status]
  end

  def translate_priority(priority)
    PRIORITY_MAP[priority]
  end

  def translate_type(labels, parent_id: false)
    return "Sub-task" if parent_id
    return "Story" if labels.nil?
    labels.split(", ").map do |label|
      return TYPE_MAP[label] if !TYPE_MAP[label].nil?
    end
    "Story"
  end

  def parse_date(date_string)
    cut_string = date_string.partition('.').first
    time_obj = DateTime.strptime(cut_string, "%Y-%m-%dT%H:%M:%S")
    format_date(time_obj)
  end

  def format_date(datetime)
    datetime.strftime("%a %b %d %Y %H:%M:%S")
  end

  def clean_date(date_time)
    return unless date_time
    date_time.partition(' GMT').first
  end

  def get_resolution(status) 
    return "Won't Do" if status == "Canceled"
    ""
  end

  def convert_markdown(text)
    text ||= ""
    text = text.to_s unless text.is_a? String
    Kramdown::Document.new(text).to_confluence
  end
}
