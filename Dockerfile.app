ARG registry
FROM ${registry}/bookmarks/base:latest

EXPOSE 3000

ENV RAILS_ENV=production

ADD  . ./
RUN sudo chown -R ${USER}:${USER} ./ && \
    bundle exec rake assets:precompile SECRET_KEY_BASE=dummy
