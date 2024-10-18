# Stage 1 - Build Stage
FROM ruby:2.6.3 AS builder

# Install Python 3.7 and pip, along with other dependencies
RUN apt-get update && \
    apt-get install -y python3.7 python3-pip && \
    rm -rf /var/lib/apt/lists/*

# Upgrade RubyGems to avoid bundler compatibility issues
RUN gem update --system 3.2.3

# Install compatible version of bundler and Sinatra
RUN gem install bundler -v 2.4.22 && gem install sinatra -v 2.0.8.1

# Set the working directory
WORKDIR /app

# Copy dependency files
COPY app/Gemfile app/Gemfile.lock ./

# Install Ruby dependencies, including Sinatra
RUN bundle install --gemfile=Gemfile --path /usr/local/bundle

# Copy the application code
COPY app /app/app

# Stage 2 - Production Stage
FROM ruby:2.6.3-slim

# Upgrade RubyGems here as well for compatibility
RUN gem update --system 3.2.3

# Set environment variables for bundler and gems
ENV GEM_HOME=/usr/local/bundle \
    BUNDLE_PATH=/usr/local/bundle \
    BUNDLE_APP_CONFIG=/usr/local/bundle \
    BUNDLE_BIN=/usr/local/bundle/bin \
    PATH=$BUNDLE_BIN:$PATH

# Set the working directory
WORKDIR /app

# Copy the application and necessary files from the builder stage
COPY --from=builder /app/app /app/app
COPY app/Gemfile app/Gemfile.lock ./

# Install bundler and Sinatra, then install dependencies
RUN gem install bundler -v 2.4.22 && gem install sinatra -v 2.0.8.1 && \
    bundle install --gemfile=Gemfile --deployment --without development test

# Expose the application port
EXPOSE 4567

# Run the application, binding it to 0.0.0.0
CMD ["ruby", "app/simpsons_simulator.rb", "-o", "0.0.0.0"]

