# coding: utf-8

require "base64"
require "functions_framework"
require 'json'
require 'net/http'
require 'uri'

class Line
  TOKEN = ""
  URI = URI.parse("https://api.line.me/v2/bot/message/broadcast")

  def make_broadcast_request(data)
    req = Net::HTTP::Post.new(URI.path)
    req["Content-Type"] = "application/json"
    req["Authorization"] = "Bearer #{TOKEN}"
    req.body = data.to_json
    return req
  end

  def send_broadcast(msg)
    data = {
      "messages" => [
        {
          "type" => "text",
          "text" => msg
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

FunctionsFramework.cloud_event "broadcast" do |event|
  msg = Base64.decode64(event.data["message"]["data"])
  line = Line.new
  line.send_broadcast(msg.force_encoding("UTF-8"))
end
