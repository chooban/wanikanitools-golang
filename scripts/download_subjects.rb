require 'net/http'
require 'uri'
require 'json'

def getResult(uri)
  uri = URI.parse(uri)
  request = Net::HTTP::Get.new(uri)
  request["Wanikani-Revision"] = "20170710"
  request["Authorization"] = "Bearer " + ENV["WANIKANI_V2_API_KEY"]

  req_options = {
    use_ssl: uri.scheme == "https",
  }

  response = Net::HTTP.start(uri.hostname, uri.port, req_options) do |http|
    http.request(request)
  end

  parsed = JSON.parse(response.body)
  return [parsed['pages']['next_url'], parsed['data']]
end

next_url = "https://api.wanikani.com/v2/subjects"
subjects = []

loop do
  puts 'Getting ' + next_url
  next_url, data = getResult(next_url)

  new_subjects = data.map {|subject|
    data = {
      "character" => subject["data"]["characters"],
      "characters" => subject["data"]["character"],
      "level" => subject["data"]["level"],
      "meanings" => subject["data"]["meanings"],
      "readings" => subject["data"]["readings"],
      "slug" => subject["data"]["slug"],
      "created_at" => subject["data"]["created_at"],
      "document_url" => subject["data"]["document_url"]
    }
    s = {
      "data" => data,
      "id" => subject["id"],
      "object" => subject["object"],
      "url" => subject["url"],
      "data_updated_at" => subject["data_updated_at"]
    }
  }
  subjects = subjects + new_subjects
  break if next_url.nil?
end

to_write = {
  "data" => subjects
}
File.open('./data/subjects.json', 'w') do |f|
  f.write(JSON.pretty_generate(to_write))
end
