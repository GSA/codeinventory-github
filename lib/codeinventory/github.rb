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
        begin
          contents_metadata = client.contents(repo[:full_name], path: ".codeinventory.yml")
          type = :yaml
          raw_content = Base64.decode64(contents_metadata[:content])
        rescue Octokit::NotFound
          begin
            contents_metadata = client.contents(repo[:full_name], path: ".codeinventory.json")
            type = :json
            raw_content = Base64.decode64(contents_metadata[:content])
          rescue Octokit::NotFound
            # Ignore repositories that don't have a CodeInventory metadata file
          end
        end
        if type == :yaml
          projects << YAML.load(raw_content).to_hash
        elsif type == :json
          projects << JSON.parse(raw_content)
        end
      end
      projects
    end

    def client
      @client ||= Octokit::Client.new(access_token: @access_token)
    end
  end
end
