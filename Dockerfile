# Use Ruby 3.2 slim image
FROM ruby:3.2-slim

# Install system dependencies
RUN apt-get update && apt-get install -y \
    build-essential \
    curl \
    git \
    && rm -rf /var/lib/apt/lists/*

# Set working directory
WORKDIR /app

# Copy Gemfile and gemspec first
COPY Gemfile ./
COPY bsb.gemspec ./
COPY lib/bsb/version.rb ./lib/bsb/version.rb

# Copy Gemfile.lock if it exists, otherwise create it
COPY Gemfile.lock* ./

# Install Ruby dependencies
RUN bundle config set --local without 'development test' && \
    bundle install --jobs 4 --retry 3

# Copy application code
COPY . .

# Create necessary directories
RUN mkdir -p log tmp/pids

# Create non-root user and set permissions
RUN useradd -m -u 1000 appuser && \
    chown -R appuser:appuser /app && \
    chmod -R 755 /app

USER appuser

# Expose port
EXPOSE 4567

# Set environment variables
ENV RACK_ENV=production
ENV PORT=4567
ENV HOST=0.0.0.0
ENV RUBYLIB="/app/lib:$RUBYLIB"

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:4567/health || exit 1

# Start the server directly with ruby
CMD ["ruby", "app.rb"]
