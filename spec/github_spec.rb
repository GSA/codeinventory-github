require "spec_helper"

describe "CodeInventory::GitHub::Source" do
  before do
    @access_token = "ABC"
    @org = "GSA"
    @source = CodeInventory::GitHub::Source.new({ access_token: @access_token }, @org)
    stub_and_return_json("https://api.github.com/orgs/GSA", "org.json")
  end

  describe ".new" do
    it "initializes a GitHub client" do
      source = CodeInventory::GitHub::Source.new({ access_token: @access_token }, @org)
      source.org.must_equal "GSA"
      source.overrides.must_be_empty
      source.exclude.must_be_empty
    end

    it "initializes a GitHub client with overrides" do
      source = CodeInventory::GitHub::Source.new({ access_token: @access_token }, @org, overrides: { "openSourceProject" => 0 })
      source.org.must_equal "GSA"
      source.overrides["openSourceProject"].must_equal 0
      source.exclude.must_be_empty
    end

    it "initializes a GitHub client with exclusions" do
      source = CodeInventory::GitHub::Source.new({ access_token: @access_token }, @org, exclude: [ "foo", "bar" ])
      source.org.must_equal "GSA"
      source.overrides.must_be_empty
      source.exclude.must_include "foo"
      source.exclude.must_include "bar"
    end

    it "initializes a GitHub client with overrides and exclusions" do
      source = CodeInventory::GitHub::Source.new({ access_token: @access_token }, @org, overrides: { "openSourceProject" => 0 }, exclude: [ "foo", "bar" ])
      source.org.must_equal "GSA"
      source.overrides["openSourceProject"].must_equal 0
      source.exclude.must_include "foo"
      source.exclude.must_include "bar"
    end
  end

  describe ".client" do
    it "provides a GitHub client" do
      @source.client.must_be_instance_of Octokit::Client
      @source.client.access_token.must_equal @access_token
    end
  end

  describe ".inventory_file" do
    describe "when a repository is empty" do
      it "gracefully returns empty data" do
        stub_and_return_json("https://api.github.com/repos/GSA/ProductOne/contents/", "repo_contents_without_inventory.json")
        stub_and_return_json("https://api.github.com/repos/GSA/ProductOne/license", "product_one_license.json")
        file = file_fixture("two_repos_one_empty.json")
        repos = JSON.load(file, nil, { symbolize_names: true, create_additions: false })
        empty_repo = @source.inventory_file(repos[1])
        empty_repo.must_be_empty
      end
    end
  end

  describe ".projects" do
    describe "when no repos have inventory files" do
      it "provides a list of projects" do
        stub_and_return_json("https://api.github.com/orgs/GSA/repos?per_page=100", "two_repos_one_private.json")
        stub_and_return_json("https://api.github.com/repos/GSA/ProductOne/contents/", "repo_contents_without_inventory.json")
        stub_and_return_json("https://api.github.com/repos/GSA/ProductOne/license", "product_one_license.json")
        stub_and_return_json("https://api.github.com/repos/GSA/ProductTwo/contents/", "repo_contents_without_inventory.json")
        stub_and_return_json("https://api.github.com/repos/GSA/ProductTwo/license", "product_two_license.json")
        projects = @source.projects
        projects.count.must_equal 2
      end
    end

    describe "when all repos have inventory files" do
      it "provides a list of projects" do
        stub_and_return_json("https://api.github.com/orgs/GSA/repos?per_page=100", "two_repos_one_private.json")
        stub_and_return_json("https://api.github.com/repos/GSA/ProductOne/contents/", "repo_contents_with_yaml_inventory.json")
        stub_and_return_json("https://api.github.com/repos/GSA/ProductOne/contents/.codeinventory.yml", "product_one_codeinventory_contents.json")
        stub_and_return_json("https://api.github.com/repos/GSA/ProductOne/license", "product_one_license.json")
        stub_and_return_json("https://api.github.com/repos/GSA/ProductTwo/contents/", "repo_contents_with_json_inventory.json")
        stub_and_return_json("https://api.github.com/repos/GSA/ProductTwo/contents/.codeinventory.json", "product_two_codeinventory_contents.json")
        stub_and_return_json("https://api.github.com/repos/GSA/ProductTwo/license", "product_two_license.json")
        projects = @source.projects
        projects.count.must_equal 2
      end
    end

    describe "when some repos have inventory files" do
      it "provides a list of projects" do
        stub_and_return_json("https://api.github.com/orgs/GSA/repos?per_page=100", "two_repos_one_private.json")
        stub_and_return_json("https://api.github.com/repos/GSA/ProductOne/contents/", "repo_contents_with_yaml_inventory.json")
        stub_and_return_json("https://api.github.com/repos/GSA/ProductOne/contents/.codeinventory.yml", "product_one_codeinventory_contents.json")
        stub_and_return_json("https://api.github.com/repos/GSA/ProductOne/license", "product_one_license.json")
        stub_and_return_json("https://api.github.com/repos/GSA/ProductTwo/contents/", "repo_contents_without_inventory.json")
        stub_and_return_json("https://api.github.com/repos/GSA/ProductTwo/license", "product_two_license.json")
        projects = @source.projects
        projects.count.must_equal 2
      end
    end

    describe "when excludes are present" do
      it "leaves out excluded repositories" do
        stub_and_return_json("https://api.github.com/orgs/GSA/repos?per_page=100", "two_repos_one_private.json")
        stub_and_return_json("https://api.github.com/repos/GSA/ProductTwo/contents/", "repo_contents_with_json_inventory.json")
        stub_and_return_json("https://api.github.com/repos/GSA/ProductTwo/contents/.codeinventory.json", "product_two_codeinventory_contents.json")
        stub_and_return_json("https://api.github.com/repos/GSA/ProductTwo/license", "product_two_license.json")
        exclusions = ["ProductOne"]
        source = CodeInventory::GitHub::Source.new({ access_token: @access_token }, @org, exclude: exclusions)
        projects = source.projects
        projects.count.must_equal 1
        projects[0]["name"].must_equal "Product Two"
      end
    end

    describe "when no inventory files or overrides are present" do
      it "uses the GitHub metadata for name" do
        stub_and_return_json("https://api.github.com/orgs/GSA/repos?per_page=100", "two_repos_one_private.json")
        stub_and_return_json("https://api.github.com/repos/GSA/ProductOne/contents/", "repo_contents_without_inventory.json")
        stub_and_return_json("https://api.github.com/repos/GSA/ProductOne/license", "product_one_license.json")
        stub_and_return_json("https://api.github.com/repos/GSA/ProductTwo/contents/", "repo_contents_without_inventory.json")
        stub_and_return_json("https://api.github.com/repos/GSA/ProductTwo/license", "product_two_license.json")
        source = CodeInventory::GitHub::Source.new({ access_token: @access_token }, @org)
        projects = source.projects
        projects[0]["name"].must_equal "ProductOne"
        projects[1]["name"].must_equal "ProductTwo"
      end

      it "uses the GitHub metadata for description" do
        stub_and_return_json("https://api.github.com/orgs/GSA/repos?per_page=100", "two_repos_one_private.json")
        stub_and_return_json("https://api.github.com/repos/GSA/ProductOne/contents/", "repo_contents_without_inventory.json")
        stub_and_return_json("https://api.github.com/repos/GSA/ProductOne/license", "product_one_license.json")
        stub_and_return_json("https://api.github.com/repos/GSA/ProductTwo/contents/", "repo_contents_without_inventory.json")
        stub_and_return_json("https://api.github.com/repos/GSA/ProductTwo/license", "product_two_license.json")
        source = CodeInventory::GitHub::Source.new({ access_token: @access_token }, @org)
        projects = source.projects
        projects[0]["description"].must_equal "An awesome product, according to the GitHub description."
        projects[1]["description"].must_equal "ProductTwo"
      end

      it "uses the GitHub metadata for license" do
        stub_and_return_json("https://api.github.com/orgs/GSA/repos?per_page=100", "two_repos_one_private.json")
        stub_and_return_json("https://api.github.com/repos/GSA/ProductOne/contents/", "repo_contents_without_inventory.json")
        stub_and_return_json("https://api.github.com/repos/GSA/ProductOne/license", "product_one_license.json")
        stub_and_return_json("https://api.github.com/repos/GSA/ProductTwo/contents/", "repo_contents_without_inventory.json")
        stub_and_return_json("https://api.github.com/repos/GSA/ProductTwo/license", "product_two_license.json")
        source = CodeInventory::GitHub::Source.new({ access_token: @access_token }, @org)
        projects = source.projects
        projects[0]["license"].must_equal "https://github.com/GSA/ProductOne/blob/dev/LICENSE.md"
        projects[1]["license"].must_equal "https://github.com/GSA/ProductTwo/blob/dev/LICENSE.md"
      end

      it "uses the GitHub metadata for openSourceProject" do
        stub_and_return_json("https://api.github.com/orgs/GSA/repos?per_page=100", "two_repos_one_private.json")
        stub_and_return_json("https://api.github.com/repos/GSA/ProductOne/contents/", "repo_contents_without_inventory.json")
        stub_and_return_json("https://api.github.com/repos/GSA/ProductOne/license", "product_one_license.json")
        stub_and_return_json("https://api.github.com/repos/GSA/ProductTwo/contents/", "repo_contents_without_inventory.json")
        stub_and_return_json("https://api.github.com/repos/GSA/ProductTwo/license", "product_two_license.json")
        source = CodeInventory::GitHub::Source.new({ access_token: @access_token }, @org)
        projects = source.projects
        projects[0]["openSourceProject"].must_equal 1
        projects[1]["openSourceProject"].must_equal 0
      end

      it "assumes true for governmentWideReuseProject" do
        stub_and_return_json("https://api.github.com/orgs/GSA/repos?per_page=100", "two_repos_one_private.json")
        stub_and_return_json("https://api.github.com/repos/GSA/ProductOne/contents/", "repo_contents_without_inventory.json")
        stub_and_return_json("https://api.github.com/repos/GSA/ProductOne/license", "product_one_license.json")
        stub_and_return_json("https://api.github.com/repos/GSA/ProductTwo/contents/", "repo_contents_without_inventory.json")
        stub_and_return_json("https://api.github.com/repos/GSA/ProductTwo/license", "product_two_license.json")
        source = CodeInventory::GitHub::Source.new({ access_token: @access_token }, @org)
        projects = source.projects
        projects[0]["governmentWideReuseProject"].must_equal 1
        projects[1]["governmentWideReuseProject"].must_equal 1
      end

      it "uses the GitHub metadata or org name for tags" do
        stub_and_return_json("https://api.github.com/orgs/GSA/repos?per_page=100", "two_repos_one_private.json")
        stub_and_return_json("https://api.github.com/repos/GSA/ProductOne/contents/", "repo_contents_without_inventory.json")
        stub_and_return_json("https://api.github.com/repos/GSA/ProductOne/license", "product_one_license.json")
        stub_and_return_json("https://api.github.com/repos/GSA/ProductTwo/contents/", "repo_contents_without_inventory.json")
        stub_and_return_json("https://api.github.com/repos/GSA/ProductTwo/license", "product_two_license.json")
        source = CodeInventory::GitHub::Source.new({ access_token: @access_token }, @org)
        projects = source.projects
        # ProjectOne has topics set, use them as tags
        projects[0]["tags"].count.must_equal 3
        projects[0]["tags"].must_include "topic1"
        projects[0]["tags"].must_include "topic2"
        projects[0]["tags"].must_include "topic3"
        # ProjectOne has no topics set, use org name as tag
        projects[1]["tags"].count.must_equal 1
        projects[1]["tags"].must_include "GSA"
      end

      it "uses the GitHub org email for contact.email" do
        stub_and_return_json("https://api.github.com/orgs/GSA/repos?per_page=100", "two_repos_one_private.json")
        stub_and_return_json("https://api.github.com/repos/GSA/ProductOne/contents/", "repo_contents_without_inventory.json")
        stub_and_return_json("https://api.github.com/repos/GSA/ProductOne/license", "product_one_license.json")
        stub_and_return_json("https://api.github.com/repos/GSA/ProductTwo/contents/", "repo_contents_without_inventory.json")
        stub_and_return_json("https://api.github.com/repos/GSA/ProductTwo/license", "product_two_license.json")
        source = CodeInventory::GitHub::Source.new({ access_token: @access_token }, @org)
        projects = source.projects
        projects[0]["contact"]["email"].must_equal "github-admins@gsa.gov"
        projects[1]["contact"]["email"].must_equal "github-admins@gsa.gov"
      end

      it "uses the GitHub URL for repository" do
        stub_and_return_json("https://api.github.com/orgs/GSA/repos?per_page=100", "two_repos_one_private.json")
        stub_and_return_json("https://api.github.com/repos/GSA/ProductOne/contents/", "repo_contents_without_inventory.json")
        stub_and_return_json("https://api.github.com/repos/GSA/ProductOne/license", "product_one_license.json")
        stub_and_return_json("https://api.github.com/repos/GSA/ProductTwo/contents/", "repo_contents_without_inventory.json")
        stub_and_return_json("https://api.github.com/repos/GSA/ProductTwo/license", "product_two_license.json")
        source = CodeInventory::GitHub::Source.new({ access_token: @access_token }, @org)
        projects = source.projects
        projects[0]["repository"].must_equal "https://github.com/GSA/ProductOne"
        projects[1]["repository"].must_be_nil
      end

      it "does not set an organization field" do
        stub_and_return_json("https://api.github.com/orgs/GSA/repos?per_page=100", "two_repos_one_private.json")
        stub_and_return_json("https://api.github.com/repos/GSA/ProductOne/contents/", "repo_contents_without_inventory.json")
        stub_and_return_json("https://api.github.com/repos/GSA/ProductOne/license", "product_one_license.json")
        stub_and_return_json("https://api.github.com/repos/GSA/ProductTwo/contents/", "repo_contents_without_inventory.json")
        stub_and_return_json("https://api.github.com/repos/GSA/ProductTwo/license", "product_two_license.json")
        source = CodeInventory::GitHub::Source.new({ access_token: @access_token }, @org)
        projects = source.projects
        projects[0].keys.wont_include "organization"
        projects[1].keys.wont_include "organization"
      end
    end

    describe "when inventory files are present" do
      it "excludes the repo if the inventory file specifies an exclude" do
        stub_and_return_json("https://api.github.com/orgs/GSA/repos?per_page=100", "two_repos_one_private.json")
        stub_and_return_json("https://api.github.com/repos/GSA/ProductOne/contents/", "repo_contents_with_yaml_inventory.json")
        stub_and_return_json("https://api.github.com/repos/GSA/ProductOne/contents/.codeinventory.yml", "product_one_codeinventory_contents_exclude.json")
        stub_and_return_json("https://api.github.com/repos/GSA/ProductOne/license", "product_one_license.json")
        stub_and_return_json("https://api.github.com/repos/GSA/ProductTwo/contents/", "repo_contents_with_json_inventory.json")
        stub_and_return_json("https://api.github.com/repos/GSA/ProductTwo/contents/.codeinventory.json", "product_two_codeinventory_contents.json")
        stub_and_return_json("https://api.github.com/repos/GSA/ProductTwo/license", "product_two_license.json")
        source = CodeInventory::GitHub::Source.new({ access_token: @access_token }, @org)
        projects = source.projects
        projects.count.must_equal 1
        projects[0]["name"].must_equal "Product Two"
      end

      it "uses the inventory file for name" do
        stub_and_return_json("https://api.github.com/orgs/GSA/repos?per_page=100", "two_repos_one_private.json")
        stub_and_return_json("https://api.github.com/repos/GSA/ProductOne/contents/", "repo_contents_with_yaml_inventory.json")
        stub_and_return_json("https://api.github.com/repos/GSA/ProductOne/contents/.codeinventory.yml", "product_one_codeinventory_contents.json")
        stub_and_return_json("https://api.github.com/repos/GSA/ProductOne/license", "product_one_license.json")
        stub_and_return_json("https://api.github.com/repos/GSA/ProductTwo/contents/", "repo_contents_with_json_inventory.json")
        stub_and_return_json("https://api.github.com/repos/GSA/ProductTwo/contents/.codeinventory.json", "product_two_codeinventory_contents.json")
        stub_and_return_json("https://api.github.com/repos/GSA/ProductTwo/license", "product_two_license.json")
        source = CodeInventory::GitHub::Source.new({ access_token: @access_token }, @org)
        projects = source.projects
        projects[0]["name"].must_equal "Product One"
        projects[1]["name"].must_equal "Product Two"
      end

      it "uses the inventory file for description" do
        stub_and_return_json("https://api.github.com/orgs/GSA/repos?per_page=100", "two_repos_one_private.json")
        stub_and_return_json("https://api.github.com/repos/GSA/ProductOne/contents/", "repo_contents_with_yaml_inventory.json")
        stub_and_return_json("https://api.github.com/repos/GSA/ProductOne/contents/.codeinventory.yml", "product_one_codeinventory_contents.json")
        stub_and_return_json("https://api.github.com/repos/GSA/ProductOne/license", "product_one_license.json")
        stub_and_return_json("https://api.github.com/repos/GSA/ProductTwo/contents/", "repo_contents_with_json_inventory.json")
        stub_and_return_json("https://api.github.com/repos/GSA/ProductTwo/contents/.codeinventory.json", "product_two_codeinventory_contents.json")
        stub_and_return_json("https://api.github.com/repos/GSA/ProductTwo/license", "product_two_license.json")
        source = CodeInventory::GitHub::Source.new({ access_token: @access_token }, @org)
        projects = source.projects
        projects[0]["description"].must_equal "An awesome product."
        projects[1]["description"].must_equal "Another awesome product, but not open source for security reasons."
      end

      it "uses the inventory file for license" do
        stub_and_return_json("https://api.github.com/orgs/GSA/repos?per_page=100", "two_repos_one_private.json")
        stub_and_return_json("https://api.github.com/repos/GSA/ProductOne/contents/", "repo_contents_with_yaml_inventory.json")
        stub_and_return_json("https://api.github.com/repos/GSA/ProductOne/contents/.codeinventory.yml", "product_one_codeinventory_contents.json")
        stub_and_return_json("https://api.github.com/repos/GSA/ProductOne/license", "product_one_license.json")
        stub_and_return_json("https://api.github.com/repos/GSA/ProductTwo/contents/", "repo_contents_with_json_inventory.json")
        stub_and_return_json("https://api.github.com/repos/GSA/ProductTwo/contents/.codeinventory.json", "product_two_codeinventory_contents.json")
        stub_and_return_json("https://api.github.com/repos/GSA/ProductTwo/license", "product_two_license.json")
        source = CodeInventory::GitHub::Source.new({ access_token: @access_token }, @org)
        projects = source.projects
        projects[0]["license"].must_equal "http://www.usa.gov/publicdomain/label/1.0/"
        projects[1]["license"].must_equal "http://www.usa.gov/publicdomain/label/1.0/"
      end

      it "uses the inventory file for openSourceProject" do
        stub_and_return_json("https://api.github.com/orgs/GSA/repos?per_page=100", "two_repos_both_private.json")
        stub_and_return_json("https://api.github.com/repos/GSA/ProductOne/contents/", "repo_contents_with_yaml_inventory.json")
        stub_and_return_json("https://api.github.com/repos/GSA/ProductOne/contents/.codeinventory.yml", "product_one_codeinventory_contents.json")
        stub_and_return_json("https://api.github.com/repos/GSA/ProductOne/license", "product_one_license.json")
        stub_and_return_json("https://api.github.com/repos/GSA/ProductTwo/contents/", "repo_contents_with_json_inventory.json")
        stub_and_return_json("https://api.github.com/repos/GSA/ProductTwo/contents/.codeinventory.json", "product_two_codeinventory_contents.json")
        stub_and_return_json("https://api.github.com/repos/GSA/ProductTwo/license", "product_two_license.json")
        source = CodeInventory::GitHub::Source.new({ access_token: @access_token }, @org)
        projects = source.projects
        projects[0]["openSourceProject"].must_equal 1
        projects[1]["openSourceProject"].must_equal 0
      end

      it "uses the inventory file for governmentWideReuseProject" do
        stub_and_return_json("https://api.github.com/orgs/GSA/repos?per_page=100", "two_repos_both_private.json")
        stub_and_return_json("https://api.github.com/repos/GSA/ProductOne/contents/", "repo_contents_with_yaml_inventory.json")
        stub_and_return_json("https://api.github.com/repos/GSA/ProductOne/contents/.codeinventory.yml", "product_one_codeinventory_contents.json")
        stub_and_return_json("https://api.github.com/repos/GSA/ProductOne/license", "product_one_license.json")
        stub_and_return_json("https://api.github.com/repos/GSA/ProductTwo/contents/", "repo_contents_with_json_inventory.json")
        stub_and_return_json("https://api.github.com/repos/GSA/ProductTwo/contents/.codeinventory.json", "product_two_codeinventory_contents.json")
        stub_and_return_json("https://api.github.com/repos/GSA/ProductTwo/license", "product_two_license.json")
        source = CodeInventory::GitHub::Source.new({ access_token: @access_token }, @org)
        projects = source.projects
        projects[0]["governmentWideReuseProject"].must_equal 1
        projects[1]["governmentWideReuseProject"].must_equal 0
      end

      it "uses the inventory file for tags" do
        stub_and_return_json("https://api.github.com/orgs/GSA/repos?per_page=100", "two_repos_one_private.json")
        stub_and_return_json("https://api.github.com/repos/GSA/ProductOne/contents/", "repo_contents_with_yaml_inventory.json")
        stub_and_return_json("https://api.github.com/repos/GSA/ProductOne/contents/.codeinventory.yml", "product_one_codeinventory_contents.json")
        stub_and_return_json("https://api.github.com/repos/GSA/ProductOne/license", "product_one_license.json")
        stub_and_return_json("https://api.github.com/repos/GSA/ProductTwo/contents/", "repo_contents_with_json_inventory.json")
        stub_and_return_json("https://api.github.com/repos/GSA/ProductTwo/contents/.codeinventory.json", "product_two_codeinventory_contents.json")
        stub_and_return_json("https://api.github.com/repos/GSA/ProductTwo/license", "product_two_license.json")
        source = CodeInventory::GitHub::Source.new({ access_token: @access_token }, @org)
        projects = source.projects
        projects[0]["tags"].count.must_equal 1
        projects[0]["tags"].must_include "usa"
        projects[1]["tags"].count.must_equal 2
        projects[1]["tags"].must_include "national-security"
        projects[1]["tags"].must_include "top-secret"
      end

      it "uses the inventory file for contact.email" do
        stub_and_return_json("https://api.github.com/orgs/GSA/repos?per_page=100", "two_repos_one_private.json")
        stub_and_return_json("https://api.github.com/repos/GSA/ProductOne/contents/", "repo_contents_with_yaml_inventory.json")
        stub_and_return_json("https://api.github.com/repos/GSA/ProductOne/contents/.codeinventory.yml", "product_one_codeinventory_contents.json")
        stub_and_return_json("https://api.github.com/repos/GSA/ProductOne/license", "product_one_license.json")
        stub_and_return_json("https://api.github.com/repos/GSA/ProductTwo/contents/", "repo_contents_with_json_inventory.json")
        stub_and_return_json("https://api.github.com/repos/GSA/ProductTwo/contents/.codeinventory.json", "product_two_codeinventory_contents.json")
        stub_and_return_json("https://api.github.com/repos/GSA/ProductTwo/license", "product_two_license.json")
        source = CodeInventory::GitHub::Source.new({ access_token: @access_token }, @org)
        projects = source.projects
        projects[0]["contact"]["email"].must_equal "example@example.com"
        projects[1]["contact"]["email"].must_equal "example@example.com"
      end

      it "uses the inventory file for repository" do
        stub_and_return_json("https://api.github.com/orgs/GSA/repos?per_page=100", "two_repos_one_private.json")
        stub_and_return_json("https://api.github.com/repos/GSA/ProductOne/contents/", "repo_contents_with_yaml_inventory.json")
        stub_and_return_json("https://api.github.com/repos/GSA/ProductOne/contents/.codeinventory.yml", "product_one_codeinventory_contents.json")
        stub_and_return_json("https://api.github.com/repos/GSA/ProductOne/license", "product_one_license.json")
        stub_and_return_json("https://api.github.com/repos/GSA/ProductTwo/contents/", "repo_contents_with_json_inventory.json")
        stub_and_return_json("https://api.github.com/repos/GSA/ProductTwo/contents/.codeinventory.json", "product_two_codeinventory_contents.json")
        stub_and_return_json("https://api.github.com/repos/GSA/ProductTwo/license", "product_two_license.json")
        source = CodeInventory::GitHub::Source.new({ access_token: @access_token }, @org)
        projects = source.projects
        projects[0]["repository"].must_equal "http://www.example.com/AlternateRepoURL"
        projects[1]["repository"].must_be_nil
      end

      it "uses the inventory file for organization" do
        stub_and_return_json("https://api.github.com/orgs/GSA/repos?per_page=100", "two_repos_one_private.json")
        stub_and_return_json("https://api.github.com/repos/GSA/ProductOne/contents/", "repo_contents_with_yaml_inventory.json")
        stub_and_return_json("https://api.github.com/repos/GSA/ProductOne/contents/.codeinventory.yml", "product_one_codeinventory_contents.json")
        stub_and_return_json("https://api.github.com/repos/GSA/ProductOne/license", "product_one_license.json")
        stub_and_return_json("https://api.github.com/repos/GSA/ProductTwo/contents/", "repo_contents_with_json_inventory.json")
        stub_and_return_json("https://api.github.com/repos/GSA/ProductTwo/contents/.codeinventory.json", "product_two_codeinventory_contents.json")
        stub_and_return_json("https://api.github.com/repos/GSA/ProductTwo/license", "product_two_license.json")
        source = CodeInventory::GitHub::Source.new({ access_token: @access_token }, @org)
        projects = source.projects
        projects[0]["organization"].must_equal "ABC Bureau"
        projects[1]["organization"].must_be_nil
      end
    end

    describe "when overrides are present" do
      it "uses the provided override for description" do
        stub_and_return_json("https://api.github.com/orgs/GSA/repos?per_page=100", "two_repos_one_private.json")
        stub_and_return_json("https://api.github.com/repos/GSA/ProductOne/contents/", "repo_contents_with_yaml_inventory.json")
        stub_and_return_json("https://api.github.com/repos/GSA/ProductOne/contents/.codeinventory.yml", "product_one_codeinventory_contents.json")
        stub_and_return_json("https://api.github.com/repos/GSA/ProductOne/license", "product_one_license.json")
        stub_and_return_json("https://api.github.com/repos/GSA/ProductTwo/contents/", "repo_contents_without_inventory.json")
        stub_and_return_json("https://api.github.com/repos/GSA/ProductTwo/license", "product_two_license.json")
        overrides = { description: "foo" }
        source = CodeInventory::GitHub::Source.new({ access_token: @access_token }, @org, overrides: overrides)
        projects = source.projects
        projects[0]["description"].must_equal "foo"
        projects[1]["description"].must_equal "foo"
      end

      it "uses the provided override for license" do
        stub_and_return_json("https://api.github.com/orgs/GSA/repos?per_page=100", "two_repos_one_private.json")
        stub_and_return_json("https://api.github.com/repos/GSA/ProductOne/contents/", "repo_contents_without_inventory.json")
        stub_and_return_json("https://api.github.com/repos/GSA/ProductTwo/contents/", "repo_contents_without_inventory.json")
        overrides = { license: "http://example.com/license" }
        source = CodeInventory::GitHub::Source.new({ access_token: @access_token }, @org, overrides: overrides)
        projects = source.projects
        projects[0]["license"].must_equal "http://example.com/license"
        projects[1]["license"].must_equal "http://example.com/license"
      end

      it "uses the provided override for openSourceProject" do
        stub_and_return_json("https://api.github.com/orgs/GSA/repos?per_page=100", "two_repos_one_private.json")
        stub_and_return_json("https://api.github.com/repos/GSA/ProductOne/contents/", "repo_contents_without_inventory.json")
        stub_and_return_json("https://api.github.com/repos/GSA/ProductOne/license", "product_one_license.json")
        stub_and_return_json("https://api.github.com/repos/GSA/ProductTwo/contents/", "repo_contents_without_inventory.json")
        stub_and_return_json("https://api.github.com/repos/GSA/ProductTwo/license", "product_two_license.json")
        overrides = { openSourceProject: 0 }
        source = CodeInventory::GitHub::Source.new({ access_token: @access_token }, @org, overrides: overrides)
        projects = source.projects
        projects[0]["openSourceProject"].must_equal 0
        projects[1]["openSourceProject"].must_equal 0
      end

      it "uses the provided override for governmentWideReuseProject" do
        stub_and_return_json("https://api.github.com/orgs/GSA/repos?per_page=100", "two_repos_one_private.json")
        stub_and_return_json("https://api.github.com/repos/GSA/ProductOne/contents/", "repo_contents_without_inventory.json")
        stub_and_return_json("https://api.github.com/repos/GSA/ProductOne/license", "product_one_license.json")
        stub_and_return_json("https://api.github.com/repos/GSA/ProductTwo/contents/", "repo_contents_without_inventory.json")
        stub_and_return_json("https://api.github.com/repos/GSA/ProductTwo/license", "product_two_license.json")
        overrides = { governmentWideReuseProject: 0 }
        source = CodeInventory::GitHub::Source.new({ access_token: @access_token }, @org, overrides: overrides)
        projects = source.projects
        projects[0]["governmentWideReuseProject"].must_equal 0
        projects[1]["governmentWideReuseProject"].must_equal 0
      end

      it "uses the provided override for tags" do
        stub_and_return_json("https://api.github.com/orgs/GSA/repos?per_page=100", "two_repos_one_private.json")
        stub_and_return_json("https://api.github.com/repos/GSA/ProductOne/contents/", "repo_contents_without_inventory.json")
        stub_and_return_json("https://api.github.com/repos/GSA/ProductOne/license", "product_one_license.json")
        stub_and_return_json("https://api.github.com/repos/GSA/ProductTwo/contents/", "repo_contents_without_inventory.json")
        stub_and_return_json("https://api.github.com/repos/GSA/ProductTwo/license", "product_two_license.json")
        overrides = { tags: [ "foo", "bar" ] }
        source = CodeInventory::GitHub::Source.new({ access_token: @access_token }, @org, overrides: overrides)
        projects = source.projects
        projects[0]["tags"].count.must_equal 2
        projects[0]["tags"].must_include "foo"
        projects[0]["tags"].must_include "bar"
        projects[1]["tags"].count.must_equal 2
        projects[1]["tags"].must_include "foo"
        projects[1]["tags"].must_include "bar"
      end

      it "uses the provided override for contact.email" do
        stub_and_return_json("https://api.github.com/orgs/GSA/repos?per_page=100", "two_repos_one_private.json")
        stub_and_return_json("https://api.github.com/repos/GSA/ProductOne/contents/", "repo_contents_without_inventory.json")
        stub_and_return_json("https://api.github.com/repos/GSA/ProductOne/license", "product_one_license.json")
        stub_and_return_json("https://api.github.com/repos/GSA/ProductTwo/contents/", "repo_contents_without_inventory.json")
        stub_and_return_json("https://api.github.com/repos/GSA/ProductTwo/license", "product_two_license.json")
        overrides = { contact: { email: "contact@example.com" } }
        source = CodeInventory::GitHub::Source.new({ access_token: @access_token }, @org, overrides: overrides)
        projects = source.projects
        projects[0]["contact"]["email"].must_equal "contact@example.com"
        projects[1]["contact"]["email"].must_equal "contact@example.com"
      end

      it "uses the provided override for repository" do
        stub_and_return_json("https://api.github.com/orgs/GSA/repos?per_page=100", "two_repos_one_private.json")
        stub_and_return_json("https://api.github.com/repos/GSA/ProductOne/contents/", "repo_contents_without_inventory.json")
        stub_and_return_json("https://api.github.com/repos/GSA/ProductOne/license", "product_one_license.json")
        stub_and_return_json("https://api.github.com/repos/GSA/ProductTwo/contents/", "repo_contents_without_inventory.json")
        stub_and_return_json("https://api.github.com/repos/GSA/ProductTwo/license", "product_two_license.json")
        overrides = { repository: "http://www.example.org/RepoOverride" }
        source = CodeInventory::GitHub::Source.new({ access_token: @access_token }, @org, overrides: overrides)
        projects = source.projects
        projects[0]["repository"].must_equal "http://www.example.org/RepoOverride"
        projects[1]["repository"].must_equal "http://www.example.org/RepoOverride"
      end

      it "uses the provided override for organization" do
        stub_and_return_json("https://api.github.com/orgs/GSA/repos?per_page=100", "two_repos_one_private.json")
        stub_and_return_json("https://api.github.com/repos/GSA/ProductOne/contents/", "repo_contents_without_inventory.json")
        stub_and_return_json("https://api.github.com/repos/GSA/ProductOne/license", "product_one_license.json")
        stub_and_return_json("https://api.github.com/repos/GSA/ProductTwo/contents/", "repo_contents_without_inventory.json")
        stub_and_return_json("https://api.github.com/repos/GSA/ProductTwo/license", "product_two_license.json")
        overrides = { organization: "XYZ Bureau" }
        source = CodeInventory::GitHub::Source.new({ access_token: @access_token }, @org, overrides: overrides)
        projects = source.projects
        projects[0]["organization"].must_equal "XYZ Bureau"
        projects[1]["organization"].must_equal "XYZ Bureau"
      end
    end
  end
end
