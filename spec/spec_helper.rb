require 'hstored_document'
require 'active_record'
require 'activerecord-postgres-hstore'

::MYSPEC_PATH = File.expand_path(File.dirname(__FILE__))
ActiveRecord::Base.establish_connection(YAML.load_file( MYSPEC_PATH + '/database.yml'))
