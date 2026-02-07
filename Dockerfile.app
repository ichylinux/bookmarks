ARG registry
FROM ${registry}/bookmarks/base:latest

EXPOSE 3000

ARG rails_env=production
ENV RAILS_ENV=${rails_env}

ADD Rakefile ./
ADD config ./config
RUN sudo chown -R ${USER}:${USER} ./ && \
    bundle exec rake dad:setup:app SECRET_KEY_BASE=dummy

ADD . ./
RUN sudo chown -R ${USER}:${USER} ./ && \
    bundle exec rake assets:precompile SECRET_KEY_BASE=dummy
