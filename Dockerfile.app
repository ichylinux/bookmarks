ARG registry
FROM ${registry}/bookmarks/base:latest

EXPOSE 3000

ENV RAILS_ENV=production

ADD  . ./
RUN sudo chown -R ${USER}:${USER} ./
RUN bundle exec rake assets:precompile
