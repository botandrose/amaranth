require "amaranth/config"
require "json"
require "net/http"

module Amaranth
  class RequestError < StandardError; end
  class RateLimitError < RequestError; end

  class Request
    MAX_RETRIES = 5
    BASE_DELAY = 1

    def self.get path
      result = request(Net::HTTP::Get.new(path))
      result.is_a?(Net::HTTPSuccess) or raise Amaranth::RequestError, "#{result.code}: #{result.body}"
      JSON.parse(result.body)
    end

    def self.post path, body
      result = request(Net::HTTP::Post.new(path), JSON.dump(body))
      result.code == "201" or raise Amaranth::RequestError, result.body
    end

    def self.put path, body
      result = request(Net::HTTP::Put.new(path), JSON.dump(body))
      result.code == "200" or raise Amaranth::RequestError, result.body
    end

    def self.delete path
      result = request(Net::HTTP::Delete.new(path))
      result.code == "200" or raise Amaranth::RequestError, result.body
    end

    def self.request req, body = nil
      retries = 0
      loop do
        response = perform(req, body)
        return response unless response.code == "429"
        if retries >= MAX_RETRIES
          raise Amaranth::RateLimitError, "429 Too Many Requests: #{req.method} #{req.path}"
        end
        sleep retry_delay(response, retries)
        retries += 1
      end
    end

    private_class_method def self.perform req, body
      Net::HTTP.start("amara.org", use_ssl: true) do |http|
        req["Content-Type"] = "application/json"
        req["X-api-username"] = Amaranth.api_username
        req["X-api-key"] = Amaranth.api_key
        req.body = body
        http.request(req)
      end
    end

    private_class_method def self.retry_delay response, retries
      seconds = response["Retry-After"].to_i
      seconds > 0 ? seconds : BASE_DELAY * (2 ** retries)
    end
  end
end
