require "amaranth/config"
require "json"
require "net/http"

module Amaranth
  class RequestError < StandardError; end

  class Request
    def self.get path
      result = request(Net::HTTP::Get.new(path))
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
      Net::HTTP.start("amara.org", use_ssl: true) do |http|
        req["Content-Type"] = "application/json"
        req["X-api-username"] = Amaranth.api_username
        req["X-api-key"] = Amaranth.api_key
        req.body = body
        http.request(req)
      end
    end
  end
end
