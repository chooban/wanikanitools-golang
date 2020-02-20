#! /bin/bash

# heroku pg:backups:capture --app wk-stats
heroku pg:backups:download --app wk-stats

pg_restore latest.dump -f build/wk-stats-with-users.sql
sed '/ALTER TABLE .* OWNER TO/d' build/wk-stats-with-users.sql > build/wk-stats.sql
rm latest.dump
