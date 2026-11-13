require "amaranth/activity"
require "webmock/rspec"

describe Amaranth::Activity do
  describe ".all" do
    it "returns a team's activity, filtered by type and start time" do
      stub_request(:get, "https://amara.org/api/teams/complexity-explorer/activity/?limit=100&type=version-added&after=2026-11-12T22:30:18Z")
        .to_return(body: <<-JSON)
          {
            "meta": { "next": null },
            "objects": [
              {
                "type": "version-added",
                "date": "2026-11-13T03:57:31Z",
                "user": { "username": "translator" },
                "video": "oimBg1fyqOEI",
                "language": "en",
                "video_uri": "https://amara.org/api/videos/oimBg1fyqOEI/",
                "language_uri": "https://amara.org/api/videos/oimBg1fyqOEI/languages/en/"
              }
            ]
          }
        JSON

      described_class.all(
        team_slug: "complexity-explorer",
        type: "version-added",
        after: Time.utc(2026, 11, 12, 22, 30, 18),
      ).should == [
        described_class.new(type: "version-added", date: "2026-11-13T03:57:31Z", video: "oimBg1fyqOEI", language: "en"),
      ]
    end

    it "returns all of a team's activity when unfiltered" do
      stub_request(:get, "https://amara.org/api/teams/complexity-explorer/activity/?limit=100")
        .to_return(body: <<-JSON)
          { "meta": { "next": null }, "objects": [{ "type": "video-added", "video": "abc123" }] }
        JSON

      described_class.all(team_slug: "complexity-explorer").should == [
        described_class.new(type: "video-added", video: "abc123"),
      ]
    end
  end
end
