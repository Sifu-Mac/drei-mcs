#!/bin/sh
set -e

rm -f /rails/tmp/pids/server.pid

bundle exec rails db:prepare

exec bundle exec puma -C config/puma.rb
