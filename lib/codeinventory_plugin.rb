require "thor"
require "codeinventory"

module CodeInventory
  module CLI
    class App < Thor
      desc "github GITHUB_ACCESS_TOKEN GITHUB_ORG [OPTIONS]", "Build an inventory from GitHub"
      option :overrides, aliases: :o, type: :hash, default: {}
      option :exclude, aliases: :e, type: :array, default: []
      def github(access_token, org)
        source = CodeInventory::GitHub.new({ access_token: access_token }, org, overrides: options[:overrides], exclude: options[:exclude])
        inventory = CodeInventory::Inventory.new(source)
        puts JSON.pretty_generate(inventory.projects)
      end
    end
  end
end
