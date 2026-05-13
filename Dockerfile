FROM ruby:3.3.1-slim

ENV APP_HOME=/rails \
    BUNDLE_DEPLOYMENT=1 \
    BUNDLE_PATH=/usr/local/bundle \
    BUNDLE_WITHOUT=development:test \
    RAILS_LOG_TO_STDOUT=true \
    RAILS_SERVE_STATIC_FILES=true

WORKDIR ${APP_HOME}

RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    curl \
    git \
    libpq-dev \
    libvips \
    pkg-config \
    postgresql-client \
  && rm -rf /var/lib/apt/lists/*

COPY Gemfile Gemfile.lock ./
RUN bundle install

COPY . .
RUN mkdir -p tmp/pids log storage && chmod +x docker/entrypoint-web.sh

ENV SECRET_KEY_BASE_DUMMY=dummy
RUN bundle exec rails assets:precompile

EXPOSE 3000
CMD ["./docker/entrypoint-web.sh"]
