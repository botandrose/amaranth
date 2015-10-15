require "amaranth/request"

module Amaranth
  class Team < Struct.new(:name, :slug)
    def self.find_by_slug slug
      if attributes = Request.get("/api/teams/#{slug}/")
        new attributes.keep_if { |key, value| members.include? key.to_sym }
      end
    end

    def initialize attributes={}
      attributes.each do |key, value|
        self[key] = value
      end
    end

    def projects
      Project.all(team_slug: slug)
    end

    def videos
      Video.all(team_slug: slug)
    end
  end
end

