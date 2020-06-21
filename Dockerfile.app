FROM bookmarks/base:latest

EXPOSE 3000

RUN bundle exec rake assets:precompile RAIL_ENV=production
