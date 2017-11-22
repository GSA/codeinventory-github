require "octokit"
require "yaml"
require "base64"

module CodeInventory
  module GitHub
    class Source
      attr_accessor :org, :overrides, :exclude

      def initialize(auth, org, overrides: {}, exclude: [])
        Octokit.auto_paginate = true
        @auth = auth
        @org = org
        @overrides = overrides
        @exclude = exclude
      end

      def project(repo_name)
        # mercy = GitHub topics preview
        # drax = GitHub license preview
        headers = {
          accept: [ "application/vnd.github.mercy-preview+json", "application/vnd.github.drax-preview+json" ]
        }
        repo = client.repository(repo_name, headers)
        inventory_file_metadata = inventory_file(repo)
        unless inventory_file_metadata.dig("codeinventory", "exclude")
          build_metadata(repo, inventory_file_metadata)
        end
      end

      def projects
        # mercy = GitHub topics preview
        # drax = GitHub license preview
        headers = {
          accept: [ "application/vnd.github.mercy-preview+json", "application/vnd.github.drax-preview+json" ]
        }
        repos = client.organization_repositories(@org, headers)
        repos.delete_if { |repo| exclude.include? repo[:name] }
        projects = []
        repos.each do |repo|
          inventory_file_metadata = inventory_file(repo)
          unless inventory_file_metadata.dig("codeinventory", "exclude")
            repo_metadata = build_metadata(repo, inventory_file_metadata)
            projects << repo_metadata
            yield repo_metadata if block_given?
          end
        end
        projects
      end

      def build_metadata(repo, inventory_file_metadata)
        repo_metadata = {}
        repo_metadata["name"] = name(repo, inventory_file_metadata)
        repo_metadata["description"] = description(repo, inventory_file_metadata)
        usage_type = usage_type(repo, inventory_file_metadata)
        repo_metadata["permissions"] = {
          "licenses" => licenses(repo, inventory_file_metadata),
          "usageType" => usage_type,
          "exemptionText" => exemption_text(repo, inventory_file_metadata)
        }
        repo_metadata["tags"] = tags(repo, inventory_file_metadata)
        repo_metadata["contact"] = { "email" => contact_email(repo, inventory_file_metadata) }
        repo_metadata["repositoryURL"] = repository(repo, inventory_file_metadata)
        repo_metadata["laborHours"] = labor_hours(repo, inventory_file_metadata)
        organization = organization(repo, inventory_file_metadata)
        repo_metadata["organization"] = organization unless organization.nil?
        repo_metadata
      end

      # Checks if the repo has an inventory file. If so, loads its metadata.
      def inventory_file(repo)
        metadata = {}
        return metadata if repo[:size] == 0 # Empty repo
        filenames = [ ".codeinventory.yml", "codeinventory.yml", ".codeinventory.json", "codeinventory.json"]
        repo_contents = client.contents(repo[:full_name], path: "/")
        inventory_file = repo_contents.select { |file| filenames.include? file[:name] }.first
        unless inventory_file.nil?
          file_content = client.contents(repo[:full_name], path: inventory_file[:path])
          raw_content = Base64.decode64(file_content[:content])
          # Remove UTF-8 BOM if there is one; it throws off JSON.parse
          raw_content.sub!("\xEF\xBB\xBF".force_encoding("ASCII-8BIT"), "")
          if inventory_file[:name].end_with? ".yml"
            metadata = YAML.load(raw_content).to_hash
          elsif inventory_file[:name].end_with? ".json"
            metadata = JSON.parse(raw_content)
          end
        end
        metadata
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

      # Provides a value for the permissions.licenses field.
      # Order of precedence:
      # 1. List of overrides
      # 2. CodeInventory metadata file
      # 3. GitHub repository license
      # 4. nil
      def licenses(repo, inventory_file_metadata)
        return @overrides[:permissions][:licenses] if @overrides.dig(:permissions, :licenses)
        return inventory_file_metadata["permissions"]["licenses"] if inventory_file_metadata.dig("permissions", "licenses")
        require 'pp'
        if repo[:license] && repo[:license][:url] && repo[:license][:spdx_id]
          return [ { "URL": repo[:license][:url], "name": repo[:license][:spdx_id] } ]
        end
        nil
      end

      # Provides a value for the permissions.usageType field.
      # Order of precedence:
      # 1. List of overrides
      # 2. CodeInventory metadata file
      # 3. GitHub repository public/private status (public=openSource; private=governmentWideReuse)
      #    Note: exempt* values must be set either in overrides or the metadata file.
      def usage_type(repo, inventory_file_metadata)
        return @overrides[:permissions][:usageType] if @overrides.dig(:permissions, :usageType)
        return inventory_file_metadata["permissions"]["usageType"] if inventory_file_metadata.dig("permissions", "usageType")
        repo[:private] ? "governmentWideReuse" : "openSource"
      end

      # Provides a value for the permissions.exemptionText field.
      # Order of precedence:
      # 1. List of overrides
      # 2. CodeInventory metadata file
      # 3. nil
      def exemption_text(repo, inventory_file_metadata)
        return @overrides[:permissions][:exemptionText] if @overrides.dig(:permissions, :exemptionText)
        return inventory_file_metadata["permissions"]["exemptionText"] if inventory_file_metadata.dig("permissions", "exemptionText")
        nil
      end

      # Provides a value for the tags field.
      # Order of precedence:
      # 1. List of overrides
      # 2. CodeInventory metadata file
      # 3. GitHub topics
      # 4. A single tag consisting of the org name.
      def tags(repo, inventory_file_metadata)
        return @overrides[:tags] if @overrides[:tags]
        return inventory_file_metadata["tags"] if inventory_file_metadata["tags"]
        return repo[:topics] unless (repo[:topics].nil? || repo[:topics].empty?)
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

      # Provies a value for the repositoryURL field.
      # Order of precedence:
      # 1. List of overrides
      # 2. CodeInventory metadata file
      # 3. If repo is public, GitHub repository URL, otherwise nil
      def repository(repo, inventory_file_metadata)
        return @overrides[:repositoryURL] if @overrides[:repositoryURL]
        return inventory_file_metadata["repositoryURL"] if inventory_file_metadata["repositoryURL"]
        repo[:private] ? nil : repo[:html_url]
      end

      # Provies a value for the laborHours field.
      # Order of precedence:
      # 1. List of overrides
      # 2. CodeInventory metadata file
      # 3. 0
      def labor_hours(repo, inventory_file_metadata)
        return @overrides[:laborHours] if @overrides[:laborHours]
        return inventory_file_metadata["laborHours"] if inventory_file_metadata["laborHours"]
        0
      end

      # Provies a value for the organization field (optional).
      # Order of precedence:
      # 1. List of overrides
      # 2. CodeInventory metadata file
      # 3. No organization field
      def organization(repo, inventory_file_metadata)
        return @overrides[:organization] if @overrides[:organization]
        return inventory_file_metadata["organization"] if inventory_file_metadata["organization"]
        nil
      end

      def client
        @client ||= Octokit::Client.new(@auth)
      end
    end
  end
end
