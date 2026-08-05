require "amaranth/request"
require "webmock/rspec"

describe Amaranth::Request do
  before { described_class.stub(:sleep) }

  describe ".get" do
    it "parses a successful response" do
      stub_request(:get, "https://amara.org/api/teams/foo/")
        .to_return(body: %({"slug": "foo"}))

      described_class.get("/api/teams/foo/").should == { "slug" => "foo" }
    end

    it "raises rather than parsing a non-JSON error page" do
      stub_request(:get, "https://amara.org/api/teams/foo/")
        .to_return(status: 503, body: "<html><body>Guru Meditation</body></html>")

      lambda {
        described_class.get("/api/teams/foo/")
      }.should raise_error(Amaranth::RequestError, /503/)
    end

    it "retries a rate limited request until it succeeds" do
      stub_request(:get, "https://amara.org/api/teams/foo/")
        .to_return(status: 429, body: "<html><body>Too Many Requests</body></html>")
        .then.to_return(body: %({"slug": "foo"}))

      described_class.get("/api/teams/foo/").should == { "slug" => "foo" }
    end

    it "gives up on a persistently rate limited request" do
      stub_request(:get, "https://amara.org/api/teams/foo/")
        .to_return(status: 429, body: "<html><body>Too Many Requests</body></html>")

      lambda {
        described_class.get("/api/teams/foo/")
      }.should raise_error(Amaranth::RateLimitError, /429/)

      WebMock.should have_requested(:get, "https://amara.org/api/teams/foo/")
        .times(Amaranth::Request::MAX_RETRIES + 1)
    end

    it "waits for the duration Amara asks for" do
      stub_request(:get, "https://amara.org/api/teams/foo/")
        .to_return(status: 429, headers: { "Retry-After" => "7" })
        .then.to_return(body: %({"slug": "foo"}))

      described_class.should_receive(:sleep).with(7)

      described_class.get("/api/teams/foo/")
    end

    it "backs off exponentially when Amara doesn't say" do
      stub_request(:get, "https://amara.org/api/teams/foo/")
        .to_return(status: 429).to_return(status: 429)
        .then.to_return(body: %({"slug": "foo"}))

      described_class.should_receive(:sleep).with(1).ordered
      described_class.should_receive(:sleep).with(2).ordered

      described_class.get("/api/teams/foo/")
    end
  end
end
