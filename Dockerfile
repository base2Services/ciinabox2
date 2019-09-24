FROM ruby:2.5-alpine

COPY . /src

WORKDIR /src

RUN apk add --no-cache git && \
    gem build ciinabox.gemspec && \
    gem install ciinabox-*.gem && \
    rm -rf /src

RUN adduser -u 1000 -D ciinabox

RUN cfndsl -u

WORKDIR /work

USER ciinabox

CMD ciinabox
