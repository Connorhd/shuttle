FROM ruby:2.3.1

RUN apt-get update -qq
RUN apt-get install -y build-essential nodejs libarchive-dev libpq-dev \
    postgresql-client cmake tidy git

ENV APP_HOME /app
RUN mkdir $APP_HOME
WORKDIR $APP_HOME

ADD Gemfile* $APP_HOME/
RUN gem update --system
RUN gem install bundler --version '>= 1.16.1' --conservative
RUN bundle config gems.contribsys.com $BUNDLE_GEMS__CONTRIBSYS__COM
RUN bundle install

ADD . $APP_HOME
