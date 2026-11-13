require "amaranth/collection"
require "time"

module Amaranth
  class Activity < Collection
    def self.all team_slug:, type: nil, after: nil
      url = "/api/teams/#{team_slug}/activity/?limit=100"
      url += "&type=#{type}" if type
      url += "&after=#{after.getutc.iso8601}" if after
      fetch(url).map do |attributes|
        new attributes.keep_if { |key, value| fields.include? key.to_sym }
      end
    end

    field :type
    field :date
    field :video
    field :language
  end
end
