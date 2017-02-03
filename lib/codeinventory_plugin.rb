require "thor"
require "codeinventory"
require "codeinventory/github"

module CodeInventory
  module CLI
    class App < Thor
      desc "github GITHUB_ORG [OPTIONS]", "Build an inventory from GitHub"
      option "access-token", aliases: "-a", type: :string, banner: "ACCESS_TOKEN"
      option "client-credentials", aliases: "-c", type: :string, banner: "CLIENT_ID:CLIENT_SECRET"
      option "login", aliases: "-l", type: :string, banner: "USERNAME:PASSWORD"
      option "overrides", aliases: "-o", type: :hash, default: {}
      option "exclude", aliases: "-e", type: :array, default: []
      def github(org)
        unless !options["access-token"].nil? ^ !options["client-credentials"].nil? ^ !options["login"].nil?
          puts "One authentication method is required (-a, -c, or -l)"
          exit 1
        end
        auth = {}
        if !options["access-token"].nil?
          auth = { access_token: options["access-token"] }
        elsif !options["client-credentials"].nil?
          values = options["client-credentials"].split(":")
          unless values.count == 2
            puts "You must provide client credentials in the format CLIENT_ID:CLIENT_SECRET"
            exit 1
          end
          auth = { client_id: values[0], client_secret: values[1] }
        elsif !options["login"].nil?
          values = options["login"].split(":")
          unless values.count == 2
            puts "You must provide a login in the format USERNAME:PASSWORD"
            exit 1
          end
          auth = { login: values[0], password: values[1] }
        end
        source = CodeInventory::GitHub::Source.new(auth, org, overrides: options[:overrides], exclude: options[:exclude])
        inventory = CodeInventory::Inventory.new(source)
        puts JSON.pretty_generate(inventory.projects)
      end
    end
  end
end
