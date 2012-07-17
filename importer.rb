require 'models/image'
require 'fastercsv'

database_configuration = YAML.load(File.read(File.join(File.dirname(__FILE__), 'database.yml')))
ActiveRecord::Base.establish_connection(database_configuration)

file_name, source = ARGV[0], ARGV[1]

csv_data = File.read(File.join(File.dirname(__FILE__), file_name))

Image.import_from_csv(csv_data, source)
