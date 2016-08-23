require "amaranth/request"

module Amaranth
  class Project < Struct.new(:name, :slug, :team_slug)
    def self.all team_slug:
      Request.get("/api/teams/#{team_slug}/projects/")["objects"].map do |attributes|
        attributes = attributes.keep_if { |key, value| members.include? key.to_sym }
        attributes["team_slug"] = team_slug
        new attributes
      end
    end

    def self.delete team_slug:, slug:
      Request.delete("/api/teams/#{team_slug}/projects/#{slug}/")
    end

    def self.create attributes
      team_slug = attributes.delete(:team_slug)
      if Request.post("/api/teams/#{team_slug}/projects/", attributes)
        new attributes
      end
    end

    def self.find team_slug:, slug:
      all(team_slug: team_slug).find { |project| project.slug == slug }
    end

    def initialize attributes={}
      attributes.each do |key, value|
        self[key] = value
      end
    end

    def videos
      Video.all(team_slug: team_slug, project_slug: slug)
    end
  end
end

