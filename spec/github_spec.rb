require "spec_helper"

describe "CodeInventory::GitHub" do
  before do
    @access_token = "ABC"
    @org = "GSA"
    @source = CodeInventory::GitHub.new(access_token: @access_token, org: @org)
  end

  describe ".new" do
    it "initializes a GitHub client" do
      @source.org.must_equal "GSA"
    end
  end

  describe ".client" do
    it "provides a GitHub client" do
      @source.client.must_be_instance_of Octokit::Client
      @source.client.access_token.must_equal @access_token
    end
  end

  describe ".projects" do
    it "provides a list of projects" do
      stub_request(:get, "https://api.github.com/orgs/GSA/repos?per_page=100").to_return(:status => 200, :body => file_fixture("two_repositories_response.json"), :headers => {"Content-Type" => "application/json"})
      stub_request(:get, "https://api.github.com/repos/GSA/ProductOne/contents/.codeinventory.yml").to_return(:status => 200, :body => file_fixture("product_one_contents_response.json"), :headers => {"Content-Type" => "application/json"})
      stub_request(:get, "https://api.github.com/repos/GSA/ProductTwo/contents/.codeinventory.yml").to_return(:status => 404)
      stub_request(:get, "https://api.github.com/repos/GSA/ProductTwo/contents/.codeinventory.json").to_return(:status => 200, :body => file_fixture("product_two_contents_response.json"), :headers => {"Content-Type" => "application/json"})
      projects = @source.projects
      projects.count.must_equal 2
      projects.first["name"].must_equal "Product One"
      projects.last["name"].must_equal "Product Two"
    end

    it "provides an empty list when there are no qualifying repositories" do
      stub_request(:get, "https://api.github.com/orgs/GSA/repos?per_page=100").to_return(:status => 200, :body => file_fixture("two_repositories_response.json"), :headers => {"Content-Type" => "application/json"})
      stub_request(:get, "https://api.github.com/repos/GSA/ProductOne/contents/.codeinventory.yml").to_return(:status => 404)
      stub_request(:get, "https://api.github.com/repos/GSA/ProductOne/contents/.codeinventory.json").to_return(:status => 404)
      stub_request(:get, "https://api.github.com/repos/GSA/ProductTwo/contents/.codeinventory.yml").to_return(:status => 404)
      stub_request(:get, "https://api.github.com/repos/GSA/ProductTwo/contents/.codeinventory.json").to_return(:status => 404)
      projects = @source.projects
      projects.must_be_empty
    end
  end
end
