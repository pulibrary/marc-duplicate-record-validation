# Note: this script assumes that you have cloned https://github.com/pulibrary/pymarc_dedupe
# in a directory next to this repository, that you have trained the matching, and that
# you have run something like `python3 main.py --file1="../marc-duplicate-record-validation/basic-benchmark.xml" --dir="experiments_files_and_output"`

require 'csv'
require 'debug'
require 'json'

csv = CSV.read('../pymarc_dedupe/experiments_files_and_output/data_matching_output.csv', headers: true)
clusters = csv.group_by { it['cluster_id'] }.values.map {|cluster| cluster.map {it['id']} }

my_output = File.open('pymarc-dedupe-results.json', 'w')
my_output.puts({clusters:}.to_json)
my_output.close

puts `bundle exec ruby run.rb benchmark pymarc-dedupe-results.json`
