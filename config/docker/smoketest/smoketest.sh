#!/bin/bash

if [[ -z $GITREPO ]]; then
  echo "make sure the GITREPO and optional GITBRANCH environment variables are set"
  echo "  GITREPO is the git repo URL"
  echo "  GITBRANCH is the BRANCH of the repo to test (default is master)"
  exit 1
fi
if [[ -z $GITBRANCH ]]; then
  export GITBRANCH=master
fi

mkdir -p ~/app
git clone --depth=1 -b ${GITBRANCH} ${GITREPO} app
if [[ $? > 0 ]]; then
  exit 1
fi
cd app
cat << DB > config/database.yml
test:
  adapter: sqlite3
  database: db/test.sqlite3
  pool: 5
  timeout: 5000
DB
storage_root="${HOME}/rads"
mkdir -p ${storage_root}
echo 'Rads::Application.config.primary_storage_root = "'${storage_root}'"' > config/initializers/rads_storage.rb
bundle config build.nokogiri --use-system-libraries
bundle --path vendor/bundle
bundle exec rake db:migrate
bundle exec rake db:seed
bundle exec rake test
