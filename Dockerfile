ARG user

FROM centos:centos7.7.1908
MAINTAINER ichylinux@gmail.com

ENV USER=$user
USER $user

RUN mkdir -p app
WORKDIR app

ADD Gemfile ./
ADD Gemfile.lock ./
RUN bundle install -j2 --without="development test"
ADD  . ./

RUN rails assets:precompile RAILS_ENV=production

EXPOSE 3000
CMD ["rails", "s", "-b", "0.0.0.0", "-e", "production"]
