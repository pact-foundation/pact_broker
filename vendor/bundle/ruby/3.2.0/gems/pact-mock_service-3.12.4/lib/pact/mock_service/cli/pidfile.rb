require 'fileutils'

module Pact
  module MockService
    class CLI < Thor
      def self.exit_on_failure? # Thor 1.0 deprecation guard
        false
      end

      class Pidfile
        attr_accessor :pid_dir, :name, :pid

        def initialize options
          @pid_dir = options[:pid_dir] || 'tmp/pids'
          @name = options[:name] || default_name
          @pid = options[:pid] || Process.pid
        end

        def file_exists?
          File.exist?(pidfile_path)
        end

        def process_running?
          process_exists? pid_from_file
        end

        def pidfile_path
          File.join(pid_dir, name)
        end

        def pid_from_file
          File.read(pidfile_path).to_i
        end

        def default_name
          File.basename($0, File.extname($0)) + ".pid"
        end

        def process_exists? pid
          Process.kill 0, pid
          true
        rescue  Errno::ESRCH
          false
        end

        def file_exists_and_process_running?
          file_exists? && process_running?
        end

        def can_start?
          if file_exists? && process_running?
            $stderr.puts "Server already running."
            false
          elsif file_exists?
            $stderr.puts "WARN: PID file #{pidfile_path} already exists, but process is not running. Overwriting pidfile."
            true
          else
            true
          end
        end

        def write
          FileUtils.mkdir_p pid_dir
          File.open(pidfile_path, "w") { |file| file << pid }
        end

        def delete
          FileUtils.rm pidfile_path
        end

        def waitpid
          tries = 0
          sleep_time = 0.1
          while process_running? && tries < 100
            sleep sleep_time
            tries += 1
          end
          raise "Process #{pid_from_file} not stopped after {100 * sleep_time} seconds." if process_running?
        end

        def kill_process
          if file_exists?
            begin
              `ps -ef | grep pact`
              Process.kill 2, pid_from_file
              waitpid
              delete
            rescue Errno::ESRCH
              $stderr.puts "Process in PID file #{pidfile_path} not running. Deleting PID file."
              delete
            end
          else
            $stderr.puts "No PID file found at #{pidfile_path}, server probably not running. Use `ps -ef | grep pact` if you suspect the process is still running."
          end
        end
      end
    end
  end
end
