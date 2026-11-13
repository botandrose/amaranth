require "amaranth/team"
require "webmock/rspec"

describe Amaranth::Team do
  describe ".find_by_slug" do
    it "retrieves a team by its slug" do
      stub_request(:get, "https://amara.org/api/teams/complexity-explorer/")
        .to_return(body: <<-JSON)
       {"name": "Complexity Explorer",
        "slug": "complexity-explorer",
        "description": "Subtitling Quickstart Guide: https://bit.ly/1JmWJEv",
        "is_visible": true,
        "membership_policy": "Application",
        "video_policy": "Admins only"}
      JSON

      team = described_class.find_by_slug("complexity-explorer")
      team.should == described_class.new({
        name: "Complexity Explorer",
        slug: "complexity-explorer",
      })
    end
  end

  describe "#projects" do
    it "returns all projects within the team" do
      projects = double
      project_factory = double
      stub_const "Amaranth::Project", project_factory

      project_factory.should_receive(:all).with(team_slug: "complexity-explorer").and_return(projects)

      team = described_class.new(slug: "complexity-explorer")
      team.projects.should == projects
    end
  end

  describe "#videos" do
    it "returns all videos within the team" do
      videos = double
      video_factory = double
      stub_const "Amaranth::Video", video_factory

      video_factory.should_receive(:all).with(team_slug: "complexity-explorer").and_return(videos)

      team = described_class.new(slug: "complexity-explorer")
      team.videos.should == videos
    end
  end

  describe "#activity" do
    it "returns the team's activity" do
      activity = double
      activity_factory = double
      stub_const "Amaranth::Activity", activity_factory
      after = Time.utc(2026, 11, 12)

      activity_factory.should_receive(:all).with(team_slug: "complexity-explorer", type: "version-added", after: after).and_return(activity)

      team = described_class.new(slug: "complexity-explorer")
      team.activity(type: "version-added", after: after).should == activity
    end
  end
end
