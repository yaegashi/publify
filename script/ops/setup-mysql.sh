#!/bin/sh

# Usage: setup-mysql [DATABASE USERNAME PASSWORD]
# Initialize databases for typo.
# Connect to the MySQL server on localhost as user 'root'.

database=${1-typo}
username=${2-typo}
password=${3-typo}

gensql() {
        cat <<-EOF
grant usage on *.* to '$2'@'localhost';
drop user '$2'@'localhost';
create user '$2'@'localhost' identified by '$3';
EOF
        for i in development test production; do
                j=${1}_${i}
                cat <<-EOF
drop database if exists $j;
create database $j character set utf8;
grant all privileges on $j.* to '$2'@'localhost';
EOF
        done
}

gensql $database $username $password | mysql -u root -p

cat <<EOF >config/database.yml
login: &login
  adapter: mysql2
  host: localhost
  username: $username
  password: $password
  encoding: utf8

development:
  database: ${database}_development
  <<: *login

test:
  database: ${database}_test
  <<: *login

production:
  database: ${database}_production
  <<: *login
EOF
