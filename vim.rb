# -*- coding : utf-8 -*-
#require "sinatra"
require "json"
require "open-uri"
require "mechanize"
require 'cgi'

get '/vim' do
  "VimAdv & :help"
end

docroot = "./doc"
jadocroot = "./ja-doc"
tags = File.read("#{docroot}/tags").lines.map {|l| l.chomp.split("\t", 3) }
agent = Mechanize.new

def VimAdv(message)
  url = [] 
  title = []
  date = []
  author = []
  count = []
  counter = 0
  command = message.strip.split(/[\s　]/)
  event = JSON.parse(open("http://api.atnd.org/events/?event_id=33746&format=json").read)
  event["events"][0]["description"].gsub(/\|(.*)\|(.*)\|(.*)\|"(.*)":(.*)\|/){
    count << $1
    date << $2
    author << $3
    title << $4
    url << $5
  }
  if command[1] == nil 
    "#{count.reverse[0]} #{date.reverse[0]} #{author.reverse[0]} #{title.reverse[0]} - #{url.reverse[0]}"
  elsif command[1] =~ /^\d+/
    "#{count[command[1].to_i-1]} #{date[command[1].to_i-1]} #{author[command[1].to_i-1]} #{title[command[1].to_i-1]} - #{url[command[1].to_i-1]}"
  elsif command[1] =~ /^(.*)/
    author.each do |a|
      if a == command[1]
        counter+=1
      end
    end
    "#{command[1]} was written #{counter} times."
  end
end

post '/vim' do
  content_type :text
  json = JSON.parse(request.body.string)
  json["events"].filter {|e| e['message'] }.map {|e|
    m = e["message"]["text"]
    if /^!VimAdv/ =~ m
      VimAdv(m)
    elsif /^:h(elp)?/ =~ m
      help = m.strip.split(/[\s　]/)
      t = tags.select {|t| t[0] == help[1].sub(/@ja/,"")}.first
      if help[1] =~ /@ja/
        docroot = jadocroot
        t[1].sub! /.txt$/, '.jax'
      end
      if t
        text = open("#{docroot}/#{t[1]}").read
        text = text[/^.*(?:\s+\*[^\n\s]+\*)*\s#{Regexp.escape(t[2][1..-1])}(?:\s+\*[^\n\s]+\*)*$/.match(text).begin(0)..-1]
        l = /\n(.*\s+\*[^\n\s]+\*|\n=+)$/.match(text)
        text = text[0.. (l ? l.begin(0) : -1)]
        docroot = './doc'
        t[1].sub! /.jax$/, '.txt'
        return text
      else
        return 'http://gyazo.com/f71ba83245a2f0d41031033de1c57109.png'
      end
    elsif /^:vimhacks$/ =~ m
      agent.get("http://vim-users.jp/category/vim-hacks/")
      return agent.page.search('h2 a').map{|e| "#{e.inner_text} - #{e['href']}"}[0,3].join("\n")
    elsif /^:vimhacks\s+?(\d+)\b/ =~ m
      agent.get("http://vim-users.jp/hack#{$1}")
      return "#{agent.page.search('h1').inner_text} - #{agent.page.uri}"
    elsif /^:vimhacks\s+?(.*)\b/ =~ m
      agent.get("http://vim-users.jp/?s=#{CGI.escape($1)}&cat=19")
      return agent.page.search('h2 a').map{|e| "#{e.inner_text} - #{e['href']}"}.select{|s| /hack/ =~ s}.join("\n")
    elsif /^またMacVimか$/ =~ m
      return 'http://bit.ly/f2fjvZ#.png'
    elsif /SEGV/ =~ m
      "キャッシュ(笑)"
    end
  }
end
