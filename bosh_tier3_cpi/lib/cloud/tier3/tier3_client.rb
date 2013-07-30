# Copyright (c) 2013 Tier 3, Inc.

module Bosh::Tier3Cloud
  class Tier3Client

    def initialize(options)
      @options = options.dup.freeze
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

    def wait_for(request_id)
      data = { RequestID: request_id }

      # NB: using 20 minute wait on everything - TODO configurable?
      # errors = [] array of exception classes that we can retry on TODO
      Bosh::Common.retryable(sleep: 10, tries: 120) do |tries, error|

        response = post('/blueprint/getblueprintstatus/json', data)
        resp_data = JSON.parse(response)

        success = resp_data['Success']
        current_status = resp_data['CurrentStatus']
        status_code = resp_data['StatusCode']
        description = resp_data['Description']

        status = false # keep retrying

        unless success
          @logger.error("Error waiting for request ID: #{request_id}, error: #{description}, status code: #{status_code}")
          status = true # stop the retries
        end

        unless current_status == 'Succeeded' or current_status == 'Failed'
          @logger.warn("Wating on request ID: #{request_id}") if tries > 0
          status = false # keep retrying
        else
          @logger.info("Completed request ID: #{request_id}")
          status = true # stop retries
        end

        status # NB: don't use return because that will exit the retries

      end
    end

    private
    def execute(path, method, data)
      base_url = @options[:url]

      @auth_token ||= get_auth_token

      url = base_url + path
      headers = { :content_type => :json, :accept => :json, "cookie" => @auth_token }
      json = data.to_json

      RestClient.send(method, url, json, headers)
    end

    private
    def get_auth_token
      auth_token_pattern = /(Tier3.API.Cookie=\S*);/
      auth_url = @options[:url] + '/auth/logon/json'

      auth_data = { APIKey: @options[:key], Password: @options[:password] }
      response = RestClient.post(
        auth_url, auth_data.to_json, :content_type => :json, :accept => :json)

      set_cookie_header = response.headers[:set_cookie]
      api_cookie = set_cookie_header.select { |cookie| cookie =~ auth_token_pattern }.first
      return api_cookie.match(auth_token_pattern)[1]
    end
  end
end
