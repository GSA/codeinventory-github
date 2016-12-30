# CodeInventory GitHub

*_This is an experimental gem that is currently in an alpha stage. The features and interface are unstable and may change at any time._*

The `codeinventory-github` gem is a [CodeInventory](https://github.com/GSA/codeinventory) plugin. This plugin allows CodeInventory to gather metadata from GitHub repositories. It builds a list of projects based on a combination of:

* `.codeinventory.yml` and `.codeinventory.json` files in GitHub repositories
* GitHub metadata
* Manually specified overrides

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
inventory.projects # Returns an array of projects in the GitHub org
```

When using `CodeInventory::GitHub`, provide a [GitHub access token](https://developer.github.com/v3/oauth/) and the GitHub organization name (e.g., "[GSA](https://github.com/GSA/)").

The `codeinventory-github` plugin will then automatically harvest your project metadata from GitHub metadata.

### Using inventory files

If you want more fine-grained control over project metadata beyond what is in the GitHub metadata, you can optionally include a `.codeinventory.yml` or `.codeinventory.json` file in the root directories of your GitHub project repositories. For each repository that has such a file, `codeinventory-github` will automatically use the metadata from it.

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
repository: https://github.com/octocat/Spoon-Knife
organization: ABC Bureau
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
  },
  "repository": "https://github.com/octocat/Spoon-Knife",
  "organization": "ABC Bureau"
}
```

### Using overrides

You can override any of the inventory fields by passing an override hash.

```ruby
overrides = {
  tags: ["my-tag-1", "my-tag-2"],
  contact: {
    email: "me@example.com"
  }
}
github_source = CodeInventory::GitHub.new(access_token: "GITHUB_ACCESS_TOKEN", org: "github_org_name", overrides: overrides)
```

In this example, `codeinventory-github` will set the tags on all your projects to `my-tag-1` and `my-tag-2` also use the contact email you specified on all projects.

### Excluding repositories

You can exclude any repository from scanning.

```ruby
exclusions = ["not-a-real-product", "DontScanMe"]
github_source = CodeInventory::GitHub.new(access_token: "GITHUB_ACCESS_TOKEN", org: "github_org_name", exclude: exclusions)
```

In this example, `codeinventory-github` will ignore the repositories named `not-a-real-product` or `DontScanMe`.

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake test` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in [`github.rb`](/lib/codeinventory/github.rb), and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/GSA/codeinventory-github.
