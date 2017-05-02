# CodeInventory GitHub

*_This is an experimental gem that is currently in an alpha stage. The features and interface are unstable and may change at any time._*

The `codeinventory-github` gem is a [CodeInventory](https://github.com/GSA/codeinventory) plugin. This plugin allows CodeInventory to gather metadata from GitHub repositories. It builds a list of projects based on a combination of:

* `.codeinventory.yml` and `.codeinventory.json` files in GitHub repositories
* GitHub metadata
* Manually specified overrides

This tool currently supports the following code.json fields:

* name
* description
* license
* openSourceProject
* governmentWideReuseProject
* tags
* contact > email
* repository
* organization

Most of these are fields required by [Code.gov](https://code.gov/). The plan is to gradually add in the rest of the optional fields.

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

auth = { access_token: "GITHUB_ACCESS_TOKEN" }
github_source = CodeInventory::GitHub::Source.new(auth, "GITHUB_ORG_NAME")

inventory = CodeInventory::Inventory.new(github_source)
inventory.projects # Returns an array of projects in the GitHub org
```

The `codeinventory-github` plugin will then automatically harvest the given organization's repository metadata from GitHub metadata.

### Authentication

This gem uses the [Octokit](https://github.com/octokit/octokit.rb) GitHub client to interface with the GitHub API.

For the `auth` parameter when instantiating `CodeInventory::GitHub::Source`, provide any type of [authentication information that Octokit supports](https://github.com/octokit/octokit.rb#authentication). Examples: a basic login/password, [OAuth access token](https://developer.github.com/v3/oauth/), or application authentication.

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

#### Excluding a repo via the metadata file

The `.codeinventory.yml` or `.codeinventory.json` file can instruct the CodeInventory tool to exclude a repository from the inventory. Use this when you have a repository that should not be included in the inventory for any reason, such as repositories that do not contain source code or contain only experimental code.

YAML (.codeinventory.yml):

```yaml
codeinventory:
  exclude: true
```

JSON (.codeinventory.json):

```json
{
  "codeinventory": {
    "exclude": true
  }
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
github_source = CodeInventory::GitHub::Source.new({ access_token: "GITHUB_ACCESS_TOKEN" }, "GITHUB_ORG_NAME", overrides: overrides)
```

In this example, `codeinventory-github` will set the tags on all your projects to `my-tag-1` and `my-tag-2` also use the contact email you specified on all projects.

### Using GitHub metadata

If the metadata file does not exist or does not contain a field, and there are no overrides, `codeinventory-github` will use GitHub metadata to populate the field. These fields can be automatically populated from GitHub metadata:

* name - GitHub repository name
* description - GitHub repository description
* license - GitHub repository license
* openSourceProject - `true` if the repository is public, `false` if it is private
* tags - GitHub repository topics
* contact > email - GitHub organization email address
* repository - GitHub repository URL

If you already specify any of the above items in your GitHub repository, there is no need to specify them in a metadata file.

### Excluding repositories

You can exclude any repository from scanning.

```ruby
exclusions = ["not-a-real-product", "DontScanMe"]
github_source = CodeInventory::GitHub::Source.new({ access_token: "GITHUB_ACCESS_TOKEN" }, "GITHUB_ORG_NAME", exclude: exclusions)
```

In this example, `codeinventory-github` will ignore the repositories named `not-a-real-product` or `DontScanMe`.

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake test` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in [`github.rb`](/lib/codeinventory/github.rb), and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/GSA/codeinventory-github.
