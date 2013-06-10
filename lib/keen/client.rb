require 'keen/http'
require 'keen/version'
require 'keen/client/publishing_methods'
require 'keen/client/querying_methods'
require 'keen/client/maintenance_methods'
require 'keen/client/helpers'
require 'keen/query'

require 'openssl'
require 'multi_json'
require 'base64'

module Keen
  class Client
    include Keen::Client::PublishingMethods
    include Keen::Client::QueryingMethods
    include Keen::Client::MaintenanceMethods
    include Keen::Client::Helpers

    attr_accessor :project_id, :write_key, :read_key, :master_key, :api_url, :api_version

    CONFIG = {
      :api_url => "https://api.keen.io",
      :api_version => "3.0",
      :api_headers => lambda { |authorization, sync_or_async|
        user_agent = "keen-gem, v#{Keen::VERSION}, #{sync_or_async}"
        user_agent += ", #{RUBY_VERSION}, #{RUBY_PLATFORM}, #{RUBY_PATCHLEVEL}"
        if defined?(RUBY_ENGINE)
          user_agent += ", #{RUBY_ENGINE}"
        end
        { "Content-Type" => "application/json",
          "User-Agent" => user_agent,
          "Authorization" => authorization }
      }
    }

    def initialize(*args)
      options = args[0]
      unless options.is_a?(Hash)
        # deprecated, pass a hash of options instead
        options = {
          :project_id => args[0],
          :write_key => args[1],
          :read_key => args[2],
        }.merge(args[3] || {})
      end

      self.project_id, self.write_key, self.read_key, self.master_key = options.values_at(
        :project_id, :write_key, :read_key, :master_key)

      self.api_url = options[:api_url] || CONFIG[:api_url]
    end

    private

    def method_missing(_method, *args, &block)
      if config = CONFIG[_method.to_sym]
        if config.is_a?(Proc)
          config.call(*args)
        else
          config
        end
      else
        super
      end
    end
  end
end
