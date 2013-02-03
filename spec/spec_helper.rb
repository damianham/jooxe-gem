require 'rubygems'
require 'yaml'
require 'sequel'

$LOAD_PATH.unshift(File.expand_path(File.dirname(__FILE__) + "/.."))

ENV.each_pair do |k,v|
  puts k + ' => ' + v if k =~ /RUBY/
end

if ENV['RUBY_VERSION'] =~ /^jruby/
  # connect to an in-memory database
  DB = Sequel.connect('jdbc:sqlite::memory:')
else
  DB = Sequel.sqlite
end

ENV['JOOXE_ROOT'] = File.expand_path(File.dirname(__FILE__) + "/../test/")

DB.sql_log_level = :debug

# load the fixtures into the db
# 
# create a users table
DB.create_table :users do
  primary_key :id
  String :account_name
  String :title
  String :given_name
  String :surname
  String :name
  String :country
  String :mail
  DateTime :updated_at
  String :updated_by
end

# create a posts table
DB.create_table :posts do
  primary_key :id
  String :title
  Integer :user_id
  DateTime :updated_at
  String :updated_by
end

# create a comments table
DB.create_table :comments do
  primary_key :id
  String :body
  Integer :post_id
  DateTime :updated_at
  String :updated_by
end

# create a bridging relationship table from users to comments
DB.create_table :user_comments do
  primary_key :id
  Integer :user_id
  Integer :comment_id
  DateTime :updated_at
  String :updated_by
end

DB.create_table :application_configs do
  primary_key :id
  String :config_key
  String :config_value
end

# insert the fixtures
['users','posts','comments','user_comments'].each do |tname|
  table = DB[tname.to_sym]
  # load the fixture with yaml
  db = YAML::load( File.open( "test/db/fixtures/#{tname}.yml" ) )

  # populate the table
  db.values.each do |v| 
    table.insert(v)
  end

end


require 'jooxe'

$default_adapter = Jooxe::SequelAdapter

# Requires supporting ruby files with custom matchers and macros, etc,
# in spec/support/ and its subdirectories.
Dir.glob("spec/support/**/*.rb").each {|f| require f}

RSpec.configure do |config|
  # == Mock Framework
  #
  # If you prefer to use mocha, flexmock or RR, uncomment the appropriate line:
  #
  # config.mock_with :mocha
  # config.mock_with :flexmock
  # config.mock_with :rr
  config.mock_with :rspec

end
