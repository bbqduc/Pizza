require 'dm-core'
require 'dm-migrations'

#DataMapper.setup( :default, ENV['DATABASE_URL'] || "sqlite3://#{Dir.pwd}/pizza.db" )
DataMapper.setup( :default, "postgres://localhost/johannes" )


