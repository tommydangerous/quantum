app_dir    = File.expand_path "../../", __FILE__
shared_dir = File.expand_path "../../shared/", __FILE__

working_directory app_dir

worker_processes 3
preload_app true # Load the app into master before forking workers
timeout 30 # Restart any workers that haven't responded in 30 seconds

# Listen on a Unix data socket
listen "#{shared_dir}/sockets/unicorn.sock", backlog: 64

stderr_path "#{shared_dir}/log/unicorn.log"
stdout_path "#{shared_dir}/log/unicorn.log"

pid "#{shared_dir}/pids/unicorn.pid"

before_fork do |server, worker|
  defined?(ActiveRecord::Base) and ActiveRecord::Base.connection.disconnect!
  old_pid = "#{server.config[:pid]}.oldbin"
  if File.exists?(old_pid) && server.pid != old_pid
    begin
      # decrement worker count of old master
      # until final new worker starts, then kill old master
      sig = (worker.nr + 1) >= server.worker_processes ? :QUIT : :TTOU
      Process.kill(sig, File.read(old_pid).to_i)
    rescue Errno::ENOENT, Errno::ESRCH
      # someone else did our job for us
    end
  end
end

after_fork do |server, worker|
  # Unicorn master loads the app then forks off workers - because of the way
  # Unit forking works, we need to make sure we aren't using any of the parent's
  # sockets, e.g. db connection
  defined?(ActiveRecord::Base) and ActiveRecord::Base.establish_connection
end

before_exec do |server|
  ENV['BUNDLE_GEMFILE'] = "#{app_dir}/Gemfile"
end
