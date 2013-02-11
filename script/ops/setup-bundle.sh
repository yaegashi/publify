#!/bin/sh

set -e

sudo apt-get install imagemagick libmysqlclient-dev
bundle install --path vendor/bundle

echo
echo "I: Please run the following command to update your database."
echo "I: bundle exec rake db:migrate RAILS_ENV=development"
