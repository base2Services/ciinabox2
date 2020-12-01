FROM ruby:2.5-alpine

ARG CIINABOX_VERSION

COPY . /src

WORKDIR /src

RUN apk add --no-cache git python3 py3-pip && \
    if [ ! -e /usr/bin/python ]; then ln -sf python3 /usr/bin/python ; fi && \
    if [ ! -e /usr/bin/pip ]; then ln -s pip3 /usr/bin/pip ; fi && \
    adduser -u 1000 -D ciinabox
    
RUN gem build ciinabox.gemspec && \
    gem install ciinabox-${CIINABOX_VERSION}.gem && \
    rm -rf /src
    
RUN cfndsl -u 11.0.0

WORKDIR /work

USER ciinabox

CMD ciinabox
