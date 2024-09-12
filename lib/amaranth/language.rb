require "amaranth/request"

module Amaranth
  class Language < Collection
    def self.all video_id:
      fetch("/api/videos/#{video_id}/languages/").map do |attributes|
        new attributes.keep_if { |key, value| fields.include? key.to_sym }
      end
    end

    field :name
    field :title
    field :description
    field :language_code
    field :versions
    field :created
    
    def updated_at
      versions.map { |hash| hash["created"] }.max
    end
  end
end
