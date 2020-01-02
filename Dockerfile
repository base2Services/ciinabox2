FROM ruby:2.5-alpine

COPY . /src

WORKDIR /src

RUN apk add --no-cache git python3 && \
    if [ ! -e /usr/bin/python ]; then ln -sf python3 /usr/bin/python ; fi && \
    if [ ! -e /usr/bin/pip ]; then ln -s pip3 /usr/bin/pip ; fi && \
    adduser -u 1000 -D ciinabox
    
RUN gem build ciinabox.gemspec && \
    gem install ciinabox-*.gem && \
    rm -rf /src
    
RUN cfndsl -u 9.0.0

WORKDIR /work

USER ciinabox

CMD ciinabox
