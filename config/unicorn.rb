rails_root = "#{File.expand_path(File.dirname(File.dirname(__FILE__)))}"

worker_processes 1
working_directory rails_root

listen "#{rails_root}/tmp/sockets/unicorn.sock"
timeout 300

stdout_path 'log/unicorn.log'
stderr_path 'log/unicorn.log'

preload_app true

before_fork do |server, worker|
  defined?(ActiveRecord::Base) and ActiveRecord::Base.connection.disconnect!

  old_pid = "#{server.config[:pid]}.oldbin"
  if old_pid != server.pid
    begin
      sig = (worker.nr + 1) >= server.worker_processes ? :QUIT : :TTOU
      Process.kill(sig, File.read(old_pid).to_i)
    rescue Errno::ENOENT, Errno::ESRCH
    end
  end
end

after_fork do |server, worker|
  defined?(ActiveRecord::Base) and ActiveRecord::Base.establish_connection
end
