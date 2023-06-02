#! /usr/bin/env ruby
require "json"
# require "debug"
require "tempfile"

eslint_output = ARGV[0]
if eslint_output.nil?
  abort "no file supplied"
end

file = File.read(eslint_output)
data_hash = JSON.parse(file)
res = data_hash.filter { |el| !el["errorCount"].zero? }.map do |el|
  {
    file_path: el["filePath"],
    messages: el["messages"].map { |arr| arr.transform_keys(&:to_sym).transform_keys(ruleId: :rule_id) }
  }
end

res.each do |obj|
  obj => { file_path: file_path, messages: messages }
  line_numbers = messages.filter { |el| el[:severity] >= 2 }.map { |el| el[:line] }

  tempfile = Tempfile.new
  begin
    File.open(tempfile.path, "a") do |output|
      File.foreach(file_path).with_index(1) do |line, line_number|
        if line_numbers.include?(line_number)

          message = messages.find { |el| el[:line] == line_number }
          message => { rule_id: rule_id, message: details }
          leading_spaces = " " * line[/\A */].size

          output.write("#{leading_spaces}// TODO: Fix this the next time the file is edited.\n")
          output.write("#{leading_spaces}// eslint-disable-next-line #{rule_id}\n")
        end
        output.write(line)
      end
    end
    FileUtils.touch(tempfile)
    FileUtils.copy_file(tempfile.path, file_path)
    puts "Added #{line_numbers.length} ignores to #{file_path}"
  ensure
    tempfile.close
    tempfile.unlink
  end
end
