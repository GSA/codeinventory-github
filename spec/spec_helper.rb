$LOAD_PATH.unshift File.expand_path("../../lib", __FILE__)
require "codeinventory/github"
require "minitest/autorun"
require "webmock/minitest"
require "pathname"

WebMock.disable_net_connect!(allow_localhost: true)

def file_fixture(fixture_name)
  file = Pathname.new(File.dirname(__FILE__)) + "fixtures" + fixture_name
  if File.exist? file
    file
  else
    raise ArgumentError, "the fixtures directory does not contain a file named '#{fixture_name}'"
  end
end

def stub_and_return_json(url, fixture_name)
  stub_request(:get, url).to_return(:status => 200, :body => file_fixture(fixture_name), :headers => {"Content-Type" => "application/json"})
end
