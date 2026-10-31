#!/usr/bin/env ruby
# encoding: utf-8

require "sinatra"
require "open-uri"
require "uri"
require "nokogiri"
require "json"
require "redis"

set :protection, :except => :path_traversal

# Permite habilitar ou desabilitar o cache
cache_enabled = ENV.fetch("CACHE_ENABLED", "true").downcase == "true"

# Conexão com Redis
redis = Redis.new(
  url: ENV["REDIS_URL"] || "redis://localhost:6379"
)

# Diretório para registrar os testes
Dir.mkdir("logs") unless Dir.exist?("logs")
cache_log = File.new("logs/extraction.log", "a")
cache_log.sync = true

get "/" do
  "Usage: http://<hostname>[:<prt>]/api/<url>"
end

get "/api/*" do

  url = [
    params["splat"].first,
    request.query_string
  ].reject(&:empty?).join("?")

  jsonlinks = nil
  cache_status = "DISABLED"

  if cache_enabled

    # Consulta o Redis
    jsonlinks = redis.get(url)

    if jsonlinks.nil?
      cache_status = "MISS"

      # Extrai os links e armazena no Redis
      jsonlinks = JSON.pretty_generate(extract_links(url))
      redis.set(url, jsonlinks)

    else
      cache_status = "HIT"
    end

  else

    # Sem cache: extrai os links em toda requisição
    jsonlinks = JSON.pretty_generate(extract_links(url))

  end

  # Registra o estado do cache
  cache_log.puts "#{Time.now.to_i}\t#{cache_status}\t#{url}"

  status 200
  headers "content-type" => "application/json"
  body jsonlinks
end

def extract_links(url)
  links = []

  doc = Nokogiri::HTML(open(url))

  doc.css("a").each do |link|
    text = link.text.strip.split.join(" ")

    begin
      links.push({
        text: text.empty? ? "[IMG]" : text,
        href: URI.join(url, link["href"])
      })
    rescue
    end
  end

  links
end

