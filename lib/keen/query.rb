require 'keen/client/helpers'

module Keen
  class Query
    include Keen::Client::Helpers
    attr_reader :params, :query_name

    def initialize(query_name, event_collection, params)
      ensure_project_id!

      if event_collection
        params[:event_collection] = event_collection.to_s
      end

      @params = params
      @query_name = query_name

    end

    def save(name)
      ensure_master_key!

      @params[:analysis_type] = @query_name
      @params[:query_name] = name

      body = @params.to_json

      begin
        response = Keen::HTTP::Sync.new(Keen.api_url).put(
            :path => api_saved_queries_resource_path(name),
            :headers => { 'Authorization' => Keen.master_key, 'content-type' => 'application/json'},
            :body => body)
      rescue Exception => http_error
        raise HttpError.new("Couldn't save #{@query_name} on Keen IO: #{http_error.message}", http_error)
      end

      response_body = response.body.chomp
      process_response(response.code, response_body)["result"]

    end

    def execute
      ensure_read_key!

      param_query = preprocess_params(@params)

      begin
        response = Keen::HTTP::Sync.new(Keen.api_url).get(
            :path => "#{api_query_resource_path(@query_name)}?#{param_query}",
            :headers => api_headers(Keen.read_key, "sync"))
      rescue Exception => http_error
        raise HttpError.new("Couldn't perform #{@query_name} on Keen IO: #{http_error.message}", http_error)
      end

      response_body = response.body.chomp
      process_response(response.code, response_body)["result"]

    end

    private

    def api_query_resource_path(analysis_type)
      "/#{Keen.api_version}/projects/#{Keen.project_id}/queries/#{analysis_type}"
    end

    def api_saved_queries_resource_path(name)
      "/#{Keen.api_version}/projects/#{Keen.project_id}/saved_queries/#{name}"
    end

  end
end
