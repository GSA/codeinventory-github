require "octokit"
require "yaml"
require "base64"

module CodeInventory
  class GitHub
    VERSION = "0.1.0"
    attr_accessor :org

    def initialize(access_token:, org:)
      Octokit.auto_paginate = true
      @access_token = access_token
      @org = org
    end

    def projects
      repos = client.organization_repositories(@org)
      projects = []
      repos.each do |repo|
        repo_contents = client.contents(repo[:full_name], path: "/")
        filenames = [ ".codeinventory.yml", "codeinventory.yml", ".codeinventory.json", "codeinventory.json"]
        inventory_file = repo_contents.select { |file| filenames.include? file[:name] }.first
        unless inventory_file.nil?
          file_content = client.contents(repo[:full_name], path: inventory_file[:path])
          raw_content = Base64.decode64(file_content[:content])
          if inventory_file[:name].end_with? ".yml"
            projects << YAML.load(raw_content).to_hash
          elsif inventory_file[:name].end_with? ".json"
            projects << JSON.parse(raw_content)
          end
        end
      end
      projects
    end

    def client
      @client ||= Octokit::Client.new(access_token: @access_token)
    end
  end
end
