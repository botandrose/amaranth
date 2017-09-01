require "amaranth/video"
require "webmock/rspec"

describe Amaranth::Video do
  describe ".all" do
    it "returns an array of hashes derived from Amara's API's 'objects' key" do
      stub_request(:get, "https://www.amara.org/api/videos/?team=complexity-explorer&limit=100")
        .to_return(body: <<-JSON)
          { "meta": {}, "objects": [{"id": 1},{"id": 2}] }
        JSON

      described_class.all(team_slug: "complexity-explorer").should == [
        Amaranth::Video.new(id: 1),
        Amaranth::Video.new(id: 2),
      ]
    end

    it "collates multiple pages" do
      stub_request(:get, "https://www.amara.org/api/videos/?team=complexity-explorer&limit=100")
        .to_return(body: <<-JSON)
          {
            "meta": {
              "next": "https://www.amara.org/api/videos/?offset=2&limit=2&team=complexity-explorer"
            },
            "objects": [{"id": 1},{"id": 2}]
          }
        JSON

      stub_request(:get, "https://www.amara.org/api/videos/?offset=2&limit=2&team=complexity-explorer")
        .to_return(body: <<-JSON)
          {
            "meta": {
              "next": null
            },
            "objects": [{"id": 3},{"id": 4}]
          }
        JSON

      described_class.all(team_slug: "complexity-explorer").should == [
        Amaranth::Video.new(id: 1),
        Amaranth::Video.new(id: 2),
        Amaranth::Video.new(id: 3),
        Amaranth::Video.new(id: 4),
      ]
    end

    it "can narrow by project" do
      stub_request(:get, "https://www.amara.org/api/videos/?team=complexity-explorer&project=introduction-to-complexity&limit=100")
        .to_return(body: <<-JSON)
          { "meta": {}, "objects": [{"id": 1},{"id": 2}] }
        JSON
      described_class.all({
        team_slug: "complexity-explorer",
        project_slug: "introduction-to-complexity",
      }).should == [
        Amaranth::Video.new(id: 1),
        Amaranth::Video.new(id: 2),
      ]
    end

    describe ".create" do
      it "creates a video with attributes" do
        stub_request(:post, "https://www.amara.org/api/videos/")
          .with(body: %({"video_url":"https://youtu.be/3f7l-Z4NF70","primary_audio_language_code":"en","team":"ce-mac-test","project":"test-project"}))
          .to_return(status: 201)

        described_class.create({
          video_url: "https://youtu.be/3f7l-Z4NF70",
          primary_audio_language_code: "en",
          team: "ce-mac-test",
          project: "test-project",
        }).should be_truthy
      end
    end

    describe ".find_by_video_url" do
      it "returns a Video for the url if one is found" do
        stub_request(:get, "https://www.amara.org/api/videos/?video_url=https://youtu.be/3f7l-Z4NF70")
          .to_return(body: %({"meta":{"previous":null,"next":null,"offset":0,"limit":20,"total_count":1},"objects":[{"id":"LrHZMMHioQHN","video_type":"Y","primary_audio_language_code":"en","original_language":"en","title":"Canon EOS 550D DSLR Camera - Sample video - Canon","description":"A sample video from the new Canon 550D DSLR camera, shot at 1920x1080 resolution (30fps) and optimised for YouTube. Offering Full HD movie recording with manual control and selectable frame rates, the EOS 550D allows you to capture your images and videos in stunning detail. Find out more about the 550D here: https://bit.ly/R4e9MB","duration":194,"thumbnail":"https://i.ytimg.com/vi/3f7l-Z4NF70/hqdefault.jpg","created":"2015-10-13T22:40:02Z","team":null,"project":null,"all_urls":["https://www.youtube.com/watch?v=3f7l-Z4NF70"],"metadata":{},"languages":[],"resource_uri":"https://www.amara.org/api/videos/LrHZMMHioQHN/"}]}))

        video = described_class.find_by_video_url "https://youtu.be/3f7l-Z4NF70"
        video.should == Amaranth::Video.new({
          "id"=>"LrHZMMHioQHN",
          "title"=>"Canon EOS 550D DSLR Camera - Sample video - Canon",
          "description"=>"A sample video from the new Canon 550D DSLR camera, shot at 1920x1080 resolution (30fps) and optimised for YouTube. Offering Full HD movie recording with manual control and selectable frame rates, the EOS 550D allows you to capture your images and videos in stunning detail. Find out more about the 550D here: https://bit.ly/R4e9MB",
          "duration"=>194,
          "primary_audio_language_code"=>"en",
          "thumbnail"=>"https://i.ytimg.com/vi/3f7l-Z4NF70/hqdefault.jpg",
          "team"=>nil,
          "project"=>nil,
          "all_urls" => ["https://www.youtube.com/watch?v=3f7l-Z4NF70"],
          "languages"=>[],
        })
      end
    end

    describe ".create_or_update_by_video_url" do
      it "updates an existing video if it exists" do
        stub_request(:post, "https://www.amara.org/api/videos/")
          .with(body: JSON.dump({
            "title":"updated title",
            "description":"updated description",
            "video_url":"https://youtu.be/3f7l-Z4NF70",
          }))
          .to_return(status: 400, body: "Video already exists for https://youtu.be/3f7l-Z4NF70")

        stub_request(:get, "https://www.amara.org/api/videos/?video_url=https://youtu.be/3f7l-Z4NF70")
          .to_return(status: 200, body: JSON.dump(
            {"objects":[{
              "id":"LrHZMMHioQHN",
              "title":"test title",
              "description":"test description",
              "duration":300,
              "primary_audio_language_code":"fr",
              "thumbnail":"https://i.ytimg.com/vi/3f7l-Z4NF70/default.jpg",
              "team":nil,
              "project":nil,
            }]}))

        stub_request(:put, "https://www.amara.org/api/videos/LrHZMMHioQHN/")
          .with(body: JSON.dump({
            "id":"LrHZMMHioQHN",
            "title":"updated title",
            "description":"updated description",
            "duration":300,
            "primary_audio_language_code":"fr",
            "thumbnail":"https://i.ytimg.com/vi/3f7l-Z4NF70/default.jpg",
            "team":nil,
            "project":nil,
          }))

        described_class.create_or_update_by_video_url("https://youtu.be/3f7l-Z4NF70", {
          title: "updated title",
          description: "updated description",
        })
      end

      it "creates a new video if it doesn't exist" do
        stub_request(:post, "https://www.amara.org/api/videos/")
          .with(body: JSON.dump({
            "title":"updated title",
            "description":"updated description",
            "video_url":"https://youtu.be/3f7l-Z4NF70",
          }))
          .to_return(status: 201)

        described_class.create_or_update_by_video_url("https://youtu.be/3f7l-Z4NF70", {
          title: "updated title",
          description: "updated description",
        })
      end
    end

    describe "#update" do
      it "updates the supplied attributes and then persists" do
        stub_request(:put, "https://www.amara.org/api/videos/LrHZMMHioQHN/")
          .with(body: %({"id":"LrHZMMHioQHN","title":"test title","description":"test description","duration":300,"primary_audio_language_code":"fr","thumbnail":"https://i.ytimg.com/vi/3f7l-Z4NF70/default.jpg","team":"ce-mac-test","project":"example-course"}))

        video = Amaranth::Video.new({
          "id"=>"LrHZMMHioQHN",
          "title"=>"Canon EOS 550D DSLR Camera - Sample video - Canon",
          "description"=>"A sample video from the new Canon 550D DSLR camera, shot at 1920x1080 resolution (30fps) and optimised for YouTube. Offering Full HD movie recording with manual control and selectable frame rates, the EOS 550D allows you to capture your images and videos in stunning detail. Find out more about the 550D here: https://bit.ly/R4e9MB",
          "duration"=>194,
          "primary_audio_language_code"=>"en",
          "thumbnail"=>"https://i.ytimg.com/vi/3f7l-Z4NF70/hqdefault.jpg",
          "team"=>nil,
          "project"=>nil,
          "all_urls" => ["https://www.youtube.com/watch?v=3f7l-Z4NF70"],
          "languages"=>[],
        })
        video.update({
          "title"=>"test title",
          "description"=>"test description",
          "duration"=>300,
          "primary_audio_language_code"=>"fr",
          "thumbnail"=>"https://i.ytimg.com/vi/3f7l-Z4NF70/default.jpg",
          "team"=>"ce-mac-test",
          "project"=>"example-course",
        })
      end
    end
  end
end

