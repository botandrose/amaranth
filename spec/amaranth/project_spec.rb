require "amaranth/project"
require "webmock/rspec"

module Amaranth
  describe Project do
    before do
      stub_request(:get, "https://amara.org/api/teams/ce-mac-test/projects/?limit=100")
        .to_return(body: <<-JSON)
          {"meta": {"previous": null, "next": null, "offset": 0, "limit": 100, "total_count": 7},
           "objects":
            [{"name": "Introduction to Complexity",
             "slug": "introduction-to-complexity",
             "description": "",
             "guidelines": null,
             "modified": "2015-08-05T01:27:11Z",
             "created": "2015-08-05T01:27:11Z",
             "workflow_enabled": false,
             "resource_uri": "https://amara.org/api/teams/complexity-explorer/projects/introduction-to-complexity/"
            },{"name": "Chaos and Dynamical Systems",
             "slug": "chaos-and-dynamical-systems",
             "description": "",
             "guidelines": null,
             "modified": "2015-08-05T01:27:30Z",
             "created": "2015-08-05T01:27:30Z",
             "workflow_enabled": false,
             "resource_uri": "https://amara.org/api/teams/complexity-explorer/projects/chaos-and-dynamical-systems/"}]}
        JSON
    end

    describe ".all" do
      it "produces project objects for each project within the supplied team" do
        Project.all(team_slug: "ce-mac-test").should == [
          Project.new(name: "Introduction to Complexity", slug: "introduction-to-complexity", team_slug: "ce-mac-test"),
          Project.new(name: "Chaos and Dynamical Systems", slug: "chaos-and-dynamical-systems", team_slug: "ce-mac-test"),
        ]
      end

      it "collates multiple pages" do
        stub_request(:get, "https://amara.org/api/teams/ce-mac-test/projects/?limit=100")
          .to_return(body: <<-JSON)
            {
              "meta": {
                "next": "https://amara.org/api/teams/ce-mac-test/projects/?offset=2&limit=2"
              },
              "objects": [{"name": 1},{"name": 2}]
            }
          JSON

        stub_request(:get, "https://amara.org/api/teams/ce-mac-test/projects/?offset=2&limit=2")
          .to_return(body: <<-JSON)
            {
              "meta": {
                "next": null
              },
              "objects": [{"name": 3},{"name": 4}]
            }
          JSON

        described_class.all(team_slug: "ce-mac-test").should == [
          Project.new(name: 1, team_slug: "ce-mac-test"),
          Project.new(name: 2, team_slug: "ce-mac-test"),
          Project.new(name: 3, team_slug: "ce-mac-test"),
          Project.new(name: 4, team_slug: "ce-mac-test"),
        ]
      end
    end

    describe ".find" do
      it "finds the project with the provided name" do
        project = Project.find(team_slug: "ce-mac-test", slug: "introduction-to-complexity")
        project.should == Project.new({
          name: "Introduction to Complexity",
          slug: "introduction-to-complexity",
          team_slug: "ce-mac-test",
        })
      end
    end

    describe ".delete" do
      it "deletes a project by name" do
        stub_request(:delete, "https://amara.org/api/teams/ce-mac-test/projects/test-project/")
        Project.delete(team_slug: "ce-mac-test", slug: "test-project").should be_truthy
      end
    end

    describe ".create" do
      it "creates a project by name" do
        stub_request(:post, "https://amara.org/api/teams/ce-mac-test/projects/")
          .with(body: %({"name":"Test Project","slug":"test-project"}))
          .to_return(status: 201)
        Project.create(team_slug: "ce-mac-test", name: "Test Project", slug: "test-project").should == Project.new(name: "Test Project", slug: "test-project")
      end
    end
  end
end
