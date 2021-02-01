# coding: utf-8

require "base64"
require "date"
require "functions_framework"
require "google/cloud/secret_manager"
require "json"
require "net/http"
require "uri"

class Line
  URI = URI.parse("https://api.line.me/v2/bot/message/broadcast")

  def get_secrets()
    project_id = ENV['PROJECT_ID']
    secret_name = ENV['SECRET_NAME']

    client = Google::Cloud::SecretManager.secret_manager_service
    key = client.secret_version_path(
      project: project_id,
      secret: secret_name,
      secret_version: 'latest'
    )
    res = client.access_secret_version(
      name: key
    )
    return JSON.parse(res.payload.data)
  end

  def make_broadcast_request(data)
    secrets = get_secrets()
    token = secrets['channel_access_token']
    req = Net::HTTP::Post.new(URI.path)
    req["Content-Type"] = "application/json"
    req["Authorization"] = "Bearer #{token}"
    req.body = data.to_json
    return req
  end

  def send_broadcast(text)
    data = {
      "messages" => [
        {
          "type" => "text",
          "text" => text
        }
      ]
    }
    http = Net::HTTP.new(URI.host, URI.port)
    req = make_broadcast_request(data)
    res = Net::HTTP.start(URI.hostname, URI.port, use_ssl: URI.scheme == "https") do |https|
      https.request(req)
    end
  end
end

def parse_log(text)
  hash = JSON.parse(text)
  text = hash['textPayload']
  timestamp = DateTime.parse(hash['timestamp'])
  timestamp = timestamp.new_offset('+09:00')
  return "#{text}\n#{timestamp.strftime("%F %T")}"
end

# Cloud Functions entry point -> broadcast
FunctionsFramework.cloud_event "broadcast" do |event|
  text = Base64.decode64(event.data["message"]["data"])
  text = parse_log(text)
  line = Line.new
  line.send_broadcast(text.force_encoding("UTF-8"))
end
