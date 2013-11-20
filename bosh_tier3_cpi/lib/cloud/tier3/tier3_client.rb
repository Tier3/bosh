# Copyright (c) 2013 Tier 3, Inc.

module Bosh::Tier3Cloud
  class Tier3Client

    def initialize(options)
      @options = options.dup.freeze
      @logger = Bosh::Clouds::Config.logger
    end

    def get(path, data)
      execute(path, :get, data)
    end

    def post(path, data)
      execute(path, :post, data)
    end

    def put(path, data)
      execute(path, :put, data)
    end

    def delete(path, data)
      execute(path, :delete, data)
    end

    def wait_for(request_id, location_alias, &on_completion)
      data = {
        RequestID: request_id,
        LocationAlias: location_alias
      }

      # Number of retries is some very large number because blueprints can take an
      # arbitrary amount of time to complete
      Bosh::Common.retryable(sleep: 10, tries: 1000000, on: [RestClient::Exception]) do |tries, error|
        response = post('/blueprint/getblueprintstatus/json', data)
        resp_data = JSON.parse(response)

        api_success = resp_data['Success']
        current_blueprint_status = resp_data['CurrentStatus']
        status_code = resp_data['StatusCode']
        description = resp_data['Description']

        should_exit = false

        if api_success
          case current_blueprint_status
          when 'Succeeded'
            @logger.debug("Completed request ID: #{request_id}")
            should_exit = true
            if block_given?
              on_completion.call(resp_data)
            end
          when 'Failed'
            raise "Blueprint #{request_id} failed with error: #{description}"
          else
            @logger.debug("Waiting on request ID: #{request_id}")
          end
        else
          raise "Error waiting for request ID: #{request_id}, error: #{description}, status code: #{status_code}"
        end

        should_exit # NB: don't use return because that will exit the retries
      end
    end

    private
    def execute(path, method, data)
      base_url = @options[:url]

      @auth_token ||= get_auth_token

      url = base_url + path
      headers = { :content_type => :json, :accept => :json, "cookie" => @auth_token }
      json = data.to_json

      @logger.debug("Executing request with URL #{url} and payload #{json}")

      response = nil
      Bosh::Common.retryable(sleep: 30, tries: 3, on: [RestClient::Exception]) do |tries, error|
        @logger.debug("Call failed with #{error}, retrying") if tries > 1
        response = RestClient::Request.execute(:method => method, :url => url, :payload => json, :headers => headers, :timeout => 180)
      end

      return response
    end

    private
    def get_auth_token
      auth_token_pattern = /(Tier3.API.Cookie=\S*);/
      auth_url = @options[:url] + '/auth/logon/json'
      auth_data = { APIKey: @options[:key], Password: @options[:password] }

      response = nil
      Bosh::Common.retryable(sleep: 30, tries: 3, on: [RestClient::Exception]) do |tries, error|
        @logger.debug("Call failed with #{error}, retrying") if tries > 1
        response = RestClient.post(auth_url, auth_data.to_json, :content_type => :json, :accept => :json)
      end

      set_cookie_header = response.headers[:set_cookie]
      api_cookie = set_cookie_header.select { |cookie| cookie =~ auth_token_pattern }.first
      return api_cookie.match(auth_token_pattern)[1]
    end
  end
end
