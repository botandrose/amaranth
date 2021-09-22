require "amaranth/request"

module Amaranth
  class Collection
    private_class_method def self.fetch url
      json = Request.get(url)
      objects = json["objects"]
      next_url = json["meta"]["next"]
      objects += fetch(next_url) if next_url
      objects
    end

    def self.field key
      @fields ||= []
      @fields << key
      attr_accessor key
    end

    def self.fields
      @fields
    end

    def initialize attributes={}
      self.attributes = attributes
    end

    def attributes= attributes
      attributes.each do |key, value|
        send :"#{key}=", value
      end
    end

    def == other
      self.attributes == other.attributes
    end

    def attributes
      self.class.fields.reduce({}) do |attrs, key|
        attrs.merge key => send(key)
      end
    end

    alias_method :to_h, :attributes
  end
end
