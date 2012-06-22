require "app_status/version"
require 'sinatra'

module AppStatus
  class Status
    class << self
      def git
        {
          revision: `cat REVISION`.chomp
        }
      end

      def uptime
        cmd = `uptime`.chomp
        {
          load: cmd.match(/load averages?: (\d+.\d+),? (\d+.\d+),? (\d+.\d+)/).try(:[], 1..3),
          days: cmd.match(/up (\d+) days/).try(:[], 1),
          users: cmd.match(/(\d+) users/).try(:[], 1)
        }
      end

      def disk_usage
        cmd = `df -h`.split("\n")
        hash = {}
        cmd[1..-1].each do |disk|
          begin
            match = disk.match(/^(\S+)\s*(\d+\S+)\s*(\d+\S+)\s*(\d+\S+)\s*(\d+\S+)\s*(\S+)/)
            hash[match[6]] = {
              filesystem: match[1],
              size: match[2],
              used: match[3],
              available: match[4],
              capacity: match[5]
            }
          rescue
            nil
          end
        end
        hash
      end
    end
  end
  
  class App < Sinatra::Base
    get '/admin/status' do
      {
        git: AppStatus::Status.git,
        uptime: AppStatus::Status.uptime,
        storage: AppStatus::Status.disk_usage
      }.to_json
    end
  end 
end
