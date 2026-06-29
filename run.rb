require 'base64'
require 'debug'
require 'marc'
require 'net/http'
require 'open-uri'
require 'uri'

Clusters = Struct.new('Clusters', :clusters, :unclustered) do
    def cluster_pairs
        clusters.map { it.combination(2).to_a }.flatten(1).map { it.sort }
    end

    def all_ids
        clusters.flatten + unclustered
    end

    def alma_ids
        all_ids.select { |id| id.start_with? '99' }
    end

    def scsb_ids
        all_ids.select { |id| id.start_with? 'SCSB-' }
    end

    def cluster_for(id)
        clusters.find { it.include? id }
    end

    def download(filename, alma_sru_endpoint: "https://princeton-psb.alma.exlibrisgroup.com/view/sru/01PRI_INST")
        writer = MARC::XMLWriter.new(filename)

        alma_ids.each_slice(10) do |slice|
            cql_query = slice.map { |id| "alma.mms_id=#{id}" }.join("%20or%20")
            uri = URI("#{alma_sru_endpoint}/?version=1.2&operation=searchRetrieve&recordSchema=marcxml&query=#{cql_query}&maximumRecords=#{alma_ids.length}")

            MARC::XMLReader.new(uri.open, parser: :nokogiri).each do |record|
                writer.write record
            end
            sleep 2
        end

        scsb_ids.each do |id|
            uri = URI("https://catalog.princeton.edu/catalog/#{id}/raw");
            raw = Net::HTTP.get(uri)
            json = JSON.parse(raw)
            decoded = Base64.strict_decode64(json['marcxml'])
            marcxml = Zlib::GzipReader.new(StringIO.new(decoded)).read
            MARC::XMLReader.new(StringIO.new(marcxml), parser: :nokogiri).each do |record|
                writer.write record
            end
        end
        writer.close
    end

    def self.from_file(path)
        parsed = JSON.parse(File.read(path), symbolize_names: true)
        new(parsed[:clusters], parsed[:unclustered])
    end

    def statistics(benchmark)
        benchmark_pairs = benchmark.cluster_pairs
        my_pairs = cluster_pairs

        puts "Total pairs in your cluster: #{my_pairs.length}"
        puts "Total pairs in benchmark cluster: #{benchmark_pairs.length}"
        puts
        puts "Found #{ my_pairs.length * 1.0 / benchmark_pairs.length } of expected pairs"
        puts "Missed #{ (benchmark_pairs - my_pairs).length } expected pairs"
        puts "Found #{ (my_pairs - benchmark_pairs).length } incorrect pairs"
        puts "#{(my_pairs - benchmark_pairs)}"
        puts
        puts "Sample pairs from your results: #{my_pairs.sample(2)}"
        puts "Sample pairs from benchmark: #{benchmark_pairs.sample(2)}"
        puts
        puts "A few pairs you missed: #{(benchmark_pairs - my_pairs).sample(5)}"
    end
end

def print_usage
    puts <<~'END_USAGE'
Usage:

```
bundle exec ruby run.rb download my-benchmark.json my-filename.xml
bundle exec ruby run.rb benchmark my-results.json my-benchmark.json
```
    END_USAGE
    exit 1
end

if ARGV[0] == 'download'
    Clusters.from_file(ARGV[1] || './basic-benchmark.json').download(ARGV[2] || 'basic-benchmark-marc.xml')
elsif ARGV[0] == 'benchmark' && ARGV[1]
    Clusters.from_file(ARGV[1]).statistics(Clusters.from_file(ARGV[2] || './basic-benchmark.json'))
else
    print_usage
end
