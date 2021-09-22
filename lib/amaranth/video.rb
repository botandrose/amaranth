require "amaranth/collection"

module Amaranth
  class Video < Collection
    field :id
    field :title
    field :description
    field :duration
    field :primary_audio_language_code
    field :thumbnail
    field :team
    field :project
    field :all_urls
    field :languages

    def self.all team_slug: nil, project_slug: nil
      url = "https://amara.org/api/videos/?limit=100"
      url += "&team=#{team_slug}" if team_slug
      url += "&project=#{project_slug}" if project_slug
      fetch(url).map do |attributes|
        new attributes.keep_if { |key, value| fields.include? key.to_sym }
      end
    end

    def self.create attributes
      Request.post("/api/videos/", attributes)
    end

    def self.find_by_video_url video_url
      if json = Request.get("/api/videos/?video_url=#{video_url}")
        attributes = json["objects"].first
        new attributes.keep_if { |key, value| fields.include? key.to_sym }
      end
    end

    def self.create_or_update_by_video_url video_url, attributes
      Amaranth::Video.create attributes.merge(video_url: video_url)
    rescue Amaranth::RequestError => exception
      raise unless exception.message.include?("Video already ")
      Amaranth::Video.find_by_video_url(video_url).update(attributes)
    end

    def update attributes={}
      self.attributes = attributes
      save
    end

    def save
      if persisted?
        save_existing
      else
        raise NotImplementedError
      end
    end

    def persisted?
      id.to_s.length > 0
    end

    private

    READONLY_ATTRIBUTES = %i(all_urls languages)
    OMIT_IF_BLANK_ATTRIBUTES = %i(duration)

    def save_existing
      attributes = to_h
      attributes.reject! { |key, value| READONLY_ATTRIBUTES.include?(key) }
      attributes.reject! { |key, value| OMIT_IF_BLANK_ATTRIBUTES.include?(key) && blank?(value) }
      Request.put("/api/videos/#{id}/", attributes)
    end

    def blank? value
      value.to_s.strip == ""
    end
  end
end

