# CodeInventory GitHub

*_This is an experimental gem that is currently in an alpha stage. The features and interface are unstable and may change at any time._*

The `codeinventory-github` gem is a [CodeInventory](https://github.com/GSA/codeinventory) plugin. This plugin allows CodeInventory to gather metadata from `.codeinventory.yml` or `.codeinventory.json` files in GitHub repositories.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'codeinventory-github'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install codeinventory-github

## Usage

Basically:

```ruby
require "codeinventory"
require "codeinventory/github"

github_source = CodeInventory::GitHub.new(access_token: "GITHUB_ACCESS_TOKEN", org: "github_org_name")

inventory = CodeInventory::Inventory.new(github_source)
inventory.projects # Returns an array of all projects in the GitHub org that have metadata
```

When using `CodeInventory::GitHub`, provide a [GitHub access token](https://developer.github.com/v3/oauth/) and the GitHub organization name (e.g., "[GSA](https://github.com/GSA/)"). Each repository within the organization that needs to be included in the project listing should have a `.codeinventory.yml` or `.codeinventory.json` file in the repository's root directory.

#### YAML Format (.codeinventory.yml)

```yaml
name: Product One
description: An awesome product.
license: http://www.usa.gov/publicdomain/label/1.0/
openSourceProject: 1
governmentWideReuseProject: 1
tags:
  - usa
contact:
  email: example@example.com
```

#### JSON Format (.codeinventory.json)

```json
{
  "name": "Product One",
  "description": "An awesome product.",
  "license": "http://www.usa.gov/publicdomain/label/1.0/",
  "openSourceProject": 1,
  "governmentWideReuseProject": 1,
  "tags": [
    "usa"
  ],
  "contact": {
    "email": "example@example.com"
  }
}
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake test` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in [`github.rb`](/lib/codeinventory/github.rb), and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/GSA/codeinventory-github.
