FROM centos

ENV RUBY_ROOT /usr/local
ENV RUBY_VERSION 2.0.0-p353

RUN yum install autoconf bison flex gcc gcc-c++ kernel-devel make m4 -y
RUN yum install libxml2-devel libxslt-devel libcurl-devel openssl-devel -y
RUN yum install git -y
RUN mkdir /src && cd /src && git clone https://github.com/sstephenson/ruby-build.git && cd ruby-build && ./install.sh && rm -rf /src/ruby-build
RUN ruby-build $RUBY_VERSION $RUBY_ROOT

RUN yum install mysql-devel mysql-libs -y

RUN gem install bundler

ADD . /app
WORKDIR /app
RUN bundle update

# CMD bundle exec bin/mbsrv
