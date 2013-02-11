#!/usr/bin/env ruby

require 'yaml'

env = ENV["RAILS_ENV"] || "production"
yml = File.expand_path('../../../config/database.yml',  __FILE__)
cfg = YAML.load_file(yml)
db = cfg[env]

abort "Database not found" if db.nil?
abort "Unsupported adapter: #{db["adapter"]}" unless db["adapter"] =~ /^mysql/

args = [
  "mysqldump",
  "--host", db["host"],
  "--user", db["username"],
  "--password="+db["password"],
  db["database"]
]

args += ARGV

exec *args
