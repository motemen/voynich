require 'optparse'
require 'pathname'
require 'json'
require 'voynich'

# build-docs.rb SOURCE [SOURCE...] [--out-dir out] [--input-encoding UTF-8]

out_dir = Pathname.new('out')
input_encoding = nil

OptionParser.new do |o|
  o.on('-d', '--out-dir DIRECTORY')  { |d|  out_dir = Pathname.new(d) }
  o.on('-I', '--input-encoding ENCODING') { |ie| input_encoding = ie }
end.parse!(ARGV)

parser = Voynich::Parser.new

STDERR.puts '1st path: generate tags'
ARGV.each do |source|
  basename = File.basename(source)
  STDERR.print "#{source}..."

  content = File.read(source, external_encoding: input_encoding)
  parser.parse(content, { filename: basename })

  STDERR.puts ' done'
end

tags_file = out_dir + 'tags.json'
STDERR.print "#{tags_file}..."
tags_file.open('w') do |io|
  io.puts JSON.generate(parser.tags)
end
STDERR.puts ' done'

STDERR.puts '2nd path: generate html'
ARGV.each do |source|
  basename = File.basename(source)
  out_file = out_dir + "doc/#{basename}.html"

  STDERR.print "#{source}..."

  content = File.read(source, external_encoding: input_encoding)
  doc = parser.parse(content, { filename: basename })

  out_file.parent.mkpath
  out_file.open('w') do |io|
    io.puts doc.to_html
  end

  STDERR.puts " #{out_file}"
end
