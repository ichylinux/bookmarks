require 'resque'
require 'resque/failure/base'
require 'resque/failure/multiple'
require 'resque/failure/redis'

Resque.redis = YAML.load_file(File.join(Rails.root, 'config', 'resque.yml'))[Rails.env]
Resque.redis.namespace = "resque:bookmarks"

module Resque
  module Failure
    class Redis
      def save
        data = {
          :failed_at => UTF8Util.clean(Time.now.strftime("%Y/%m/%d %H:%M:%S %Z")),
          :payload   => payload,
          :exception => exception.class.to_s,
          :error     => exception.to_s, #UTF8Util.clean(exception.to_s), UTF8Util.cleanを呼ぶと文字化けする
          :backtrace => filter_backtrace(Array(exception.backtrace)),
          :worker    => worker.to_s,
          :queue     => queue
        }
        data = Resque.encode(data)
        Resque.redis.rpush(:failed, data)
      end
    end
  end
end

module Resque
  module Failure
    class Log < Base
      def save
        Rails.logger.error [
          "Resque #{queue}:#{worker}",
          "#{payload}",
          "#{exception.class} #{exception.to_s}",
          "#{exception.backtrace.join("\n")}"
        ].join("\n")
      end
    end
  end
end

Resque::Failure::Multiple.configure do |multi|
  multi.classes = [Resque::Failure::Redis, Resque::Failure::Log]
end
