require "octokit"
require "yaml"
require "base64"

module CodeInventory
  class GitHub
    VERSION = "0.1.0"
    attr_accessor :org, :overrides, :exclude

    def initialize(access_token:, org:, overrides: {}, exclude: [])
      Octokit.auto_paginate = true
      @access_token = access_token
      @org = org
      @overrides = overrides
      @exclude = exclude
    end

    def projects
      repos = client.organization_repositories(@org)
      repos.delete_if { |repo| exclude.include? repo[:name] }
      projects = []
      repos.each do |repo|
        inventory_file_metadata = inventory_file(repo)
        repo_metadata = {}
        repo_metadata["name"] = name(repo, inventory_file_metadata)
        repo_metadata["description"] = description(repo, inventory_file_metadata)
        repo_metadata["license"] = license(repo, inventory_file_metadata)
        repo_metadata["openSourceProject"] = open_source_project(repo, inventory_file_metadata)
        repo_metadata["governmentWideReuseProject"] = government_wide_reuse_project(repo, inventory_file_metadata)
        repo_metadata["tags"] = tags(repo, inventory_file_metadata)
        repo_metadata["contact"] = { "email" => contact_email(repo, inventory_file_metadata) }
        projects << repo_metadata
      end
      projects
    end

    # Checks if the repo has an inventory file. If so, loads its metadata.
    def inventory_file(repo)
      filenames = [ ".codeinventory.yml", "codeinventory.yml", ".codeinventory.json", "codeinventory.json"]
      repo_contents = client.contents(repo[:full_name], path: "/")
      inventory_file = repo_contents.select { |file| filenames.include? file[:name] }.first
      unless inventory_file.nil?
        file_content = client.contents(repo[:full_name], path: inventory_file[:path])
        raw_content = Base64.decode64(file_content[:content])
        if inventory_file[:name].end_with? ".yml"
          metadata = YAML.load(raw_content).to_hash
        elsif inventory_file[:name].end_with? ".json"
          metadata = JSON.parse(raw_content)
        end
      end
      metadata || {}
    end

    # Provides a value for the name field.
    # Order of precedence:
    # 1. CodeInventory metadata file
    # 2. GitHub repository name
    def name(repo, inventory_file_metadata)
      return inventory_file_metadata["name"] if inventory_file_metadata["name"]
      repo[:name]
    end

    # Provides a value for the description field.
    # Order of precedence:
    # 1. List of overrides
    # 2. CodeInventory metadata file
    # 3. GitHub repository description
    # 4. GitHub repository name
    def description(repo, inventory_file_metadata)
      return @overrides[:description] if @overrides[:description]
      return inventory_file_metadata["description"] if inventory_file_metadata["description"]
      return repo[:description] if repo[:description]
      repo[:name]
    end

    # Provides a value for the license field.
    # Order of precedence:
    # 1. List of overrides
    # 2. CodeInventory metadata file
    # 3. LICENSE.md or LICENSE file in the repository
    # 4. nil
    def license(repo, inventory_file_metadata)
      return @overrides[:license] if @overrides[:license]
      return inventory_file_metadata["license"] if inventory_file_metadata["license"]
      # Need to set header to quiet warning about using a GitHub preview feature
      headers = { accept: "application/vnd.github.drax-preview+json" }
      begin
        license_meta = client.repository_license_contents(repo[:full_name], headers)
        license = license_meta[:html_url]
      rescue Octokit::NotFound ; end
      license
    end

    # Provides a value for the openSourceProject field.
    # Order of precedence:
    # 1. List of overrides
    # 2. CodeInventory metadata file
    # 3. GitHub repository public/private status (public=1; private=0)
    def open_source_project(repo, inventory_file_metadata)
      return @overrides[:openSourceProject] if @overrides[:openSourceProject]
      return inventory_file_metadata["openSourceProject"] if inventory_file_metadata["openSourceProject"]
      repo[:private] ? 0 : 1
    end

    # Provides a value for the governmentWideReuseProject field.
    # Order of precedence:
    # 1. List of overrides
    # 2. CodeInventory metadata file
    # 3. 1 (assume government-wide reuse)
    def government_wide_reuse_project(repo, inventory_file_metadata)
      return @overrides[:governmentWideReuseProject] if @overrides[:governmentWideReuseProject]
      return inventory_file_metadata["governmentWideReuseProject"] if inventory_file_metadata["governmentWideReuseProject"]
      1
    end

    # Provides a value for the tags field.
    # Order of precedence:
    # 1. List of overrides
    # 2. CodeInventory metadata file
    # 3. A single tag consisting of the org name.
    def tags(repo, inventory_file_metadata)
      return @overrides[:tags] if @overrides[:tags]
      return inventory_file_metadata["tags"] if inventory_file_metadata["tags"]
      [repo[:owner][:login]]
    end

    # Provides a value for the contact.email field.
    # Order of precedence:
    # 1. List of overrides
    # 2. CodeInventory metadata file
    # 3. GitHub organization email
    def contact_email(repo, inventory_file_metadata)
      return @overrides[:contact][:email] if @overrides.dig(:contact, :email)
      return inventory_file_metadata["contact"]["email"] if inventory_file_metadata.dig("contact", "email")
      org = client.organization(@org)
      org[:email]
    end

    def client
      @client ||= Octokit::Client.new(access_token: @access_token)
    end
  end
end
