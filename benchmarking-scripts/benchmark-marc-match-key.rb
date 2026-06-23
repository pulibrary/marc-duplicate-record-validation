require 'debug'
require 'marc_match_key'

keys = MARC::XMLReader.new('./basic-benchmark-marc.xml').map do |record|
    [MarcMatchKey::Key.new(record).key, record['001'].value]
end

my_output = File.open('marc-match-key-results.json', 'w')
my_output.puts({clusters: keys.group_by { it[0] }.values.map{ |cluster| cluster.map{ it[1]} }}.to_json)
my_output.close

puts `bundle exec ruby run.rb benchmark marc-match-key-results.json`
