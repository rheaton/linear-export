require 'csv'

module Common
  module CsvUtils
    # per security audit, strip out leading special characters from CSV cells to prevent CSV formula injection
    BLACKLISTED_LEADING_CHARS = %w[+ - @ | =].freeze

    # Wrapper around the ruby CSV.generate method, prepending strings with leading special characters with a space to
    # prevent Excel or other spreadsheet editors from interpreting the cell value as a formula
    # Anywhere we use CSV.generate(*args, **options), we should instead use ::Common::CsvUtils.generate(*args, **options)
    def self.generate(str = nil, **options)
      csv_rows = []

      yield csv_rows

      updated_rows = csv_rows.collect { |row| ::Common::CsvUtils.sanitize_row(row) }

      generated_csv = CSV.generate(str, **options) do |actual_csv|
        updated_rows.each { |row| actual_csv << row }
      end
      generated_csv
    end

    def self.generate_by_line(data, headers, output = "")
      output << CSV.generate_line(::Common::CsvUtils.sanitize_row(headers)) if headers.present?
      data.each do |row|
        output << CSV.generate_line(::Common::CsvUtils.sanitize_row(row))
      end
      output
    end

    def self.sanitize_row(row)
      row.collect do |cell|
        cell.is_a?(String) && BLACKLISTED_LEADING_CHARS.include?(cell[0]) ? cell.prepend(' ') : cell
      end
    end

    def self.generate_csv_from_headers_and_rows(headers, rows)
      ::Common::CsvUtils.generate(headers: true) do |csv|
        csv << headers
        rows.each do |row|
          csv << headers.map { |header| row[header] }
        end
      end
    end

    def self.friendly_name(enterprise)
      enterprise.friendly_name.tr(' ', '_').downcase
    end
  end
end
