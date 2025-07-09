# frozen_string_literal: true

# Puma configuration for BSB Web Service

# Set the environment
environment ENV['RACK_ENV'] || 'development'

# Configure the server
port ENV['PORT'] || 4567
bind "tcp://#{ENV['HOST'] || 'localhost'}:#{ENV['PORT'] || 4567}"

# Worker processes
workers ENV['WEB_CONCURRENCY'] || 2

# Threads
threads_count = ENV['RAILS_MAX_THREADS'] || 5
threads threads_count, threads_count

# Preload the application
preload_app!

# Allow puma to be restarted by `rails restart` command
plugin :tmp_restart

# Logging - only redirect if directories exist
if ENV['RACK_ENV'] == 'production'
  if Dir.exist?('log')
    stdout_redirect 'log/puma.out', 'log/puma.err', true
  end
end

# PID file - only if tmp/pids directory exists
if ENV['RACK_ENV'] == 'production' && Dir.exist?('tmp/pids')
  pidfile 'tmp/pids/puma.pid'
end

# On worker boot (for database connections, etc.)
on_worker_boot do
  # Worker specific setup
end

# Before fork (for shared resources)
before_fork do
  # Shared setup
end
