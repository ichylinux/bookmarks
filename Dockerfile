FROM bookmarks-app:latest

ARG user
ENV USER=$user

RUN mkdir -p app
WORKDIR app

ADD Gemfile ./
ADD Gemfile.lock ./
RUN sudo chown -R $USER:$USER ./
RUN bundle install -j2 --without="development test"
ADD  . ./
RUN sudo chown -R $USER:$USER ./

RUN rails assets:precompile RAILS_ENV=production

EXPOSE 3000
CMD ["rails", "s", "-b", "0.0.0.0", "-e", "production"]
