# -*- coding : utf-8 -*-
#require "sinatra"
require "json"
require "open-uri"
require "mechanize"
require 'cgi'

get '/vim' do
  "VimAdv & :help"
end

def Help(m, docroot, jadocroot, tags)
  help = m.strip.split(/[\s　]/)
  t = tags.detect {|t| t[0] == help[1].sub(/@ja/,"").sub("+","\\+")}
  if help[1] =~ /@ja/
    docroot = jadocroot
    t[1].sub! /.txt$/, '.jax'
  end
  return 'http://gyazo.com/f71ba83245a2f0d41031033de1c57109.png' unless t
  text = File.read("#{docroot}/#{t[1]}")
  text = text[/^.*(?:\s+\*[^\n\s]+\*)*\s#{Regexp.escape(t[2][1..-1])}(?:\s+\*[^\n\s]+\*)*$/.match(text).begin(0)..-1]
  l = /\n(.*\s+\*[^\n\s]+\*|\n=+)$/.match(text)
  text = text[0.. (l ? l.begin(0) : -1)]
  docroot = './doc'
  t[1].sub! /.jax$/, '.txt'
  text
end

def VimAdv(event)
  data = Hash.new
  user = [];search=[]
  command = event['message']["text"].strip.split(/[\s　]/)
  room = event['message']['room']
  atnd = JSON.parse(open("http://api.atnd.org/events/?event_id=33746&format=json").read)
  atnd["events"][0]["description"].gsub(/\|(.*)\|(.*)\|(.*)\|"(.*)":(.*)\|/) {
    data[$1] = {"count" => $1, "date" => $2, "author" => $3, "title" => $4, "url" => $5}
  }
  data = data.sort
  query = ['version=2.0.1&longUrl=', '&login=raaniconama&apiKey=R_446879b310c0e904023fdda3e0b97998']
  case command[1]
  when nil
    last = data[-1][-1]
    result = JSON.parse(open("http://api.bit.ly/shorten?#{query[0]}#{last["url"]}#{query[1]}").read)
    "#{last["count"]} #{last["date"]} #{last["author"]} #{last["title"]} - #{result["results"][last["url"]]["shortUrl"]}"
  when /^\d+/
    day = data["%03d"%command[1]][-1]
    result = JSON.parse(open("http://api.bit.ly/shorten?#{query[0]}#{day["url"]}#{query[1]}").read)
    "#{day["count"]} #{day["date"]} #{day["author"]} #{day["title"]} - #{result["results"][day["url"]]["shortUrl"]}"
#  when /#ranking(\d+)?/ 
#    rank = 10 if $1 == nil && command[2] == nil 
#    rank = $1.to_i if $1.to_i > 0
#    rank = command[2].to_i if command[2].to_i > 0
#    ranking = data.map {|v| v[1]["author"]}.each_with_object(Hash.new(0)){|o,h|h[o]+=1}.sort_by{|o,h|h}.reverse
#    if rank > 50
#      split = open("http://lingr.com/api/room/say?room=#{room}&bot=VimAdv&text=#{CGI.escape("#{ranking[0..50].group_by{|i,j|j}.map{|a|a[1]}.map{|a|a.map{|a|a.reverse}.join("").sub(/^(\d+)/){i="%02d"%($1.to_i);"#{i}回:"}.gsub(/\d@/){", @"}}.join("\n")}")}&bot_verifier=f970a5aec3cbd149343aa5a4fec3a43e68d01e4a").read
#      "#{ranking[51..rank-1].group_by{|i,j|j}.map{|a|a[1]}.map{|a|a.map{|a|a.reverse}.join("").sub(/^(\d+)/){"#{$1.to_i}回:"}.gsub(/\d\@/){", @"}}.join("\n")}"
#    else
#      "#{ranking[0..rank-1].group_by{|i,j|j}.map{|a|a[1]}.map{|a|a.map{|a|a.reverse}.join("").sub(/^(\d+)/){"#{$1.to_i}回:"}.gsub(/\d\@/){", @"}}.join("\n")}"
#    end
  when /^(.*)/
    command[1] = event["message"]["speaker_id"] if command[1] == "#me"
    command[1] = "ujihisa" if command[1] == "u"
    data.map {|v|
      if /#{command[1]}/ =~ v[-1]["author"]
        result = JSON.parse(open("http://api.bit.ly/shorten?#{query[0]}#{v[-1]["url"]}#{query[1]}").read)
        user << "#{v[-1]["count"]} #{v[-1]["date"]} #{v[-1]["author"]} #{v[-1]["title"]} - #{result["results"][v[-1]["url"]]["shortUrl"]}"
      end
    }
    if user.length >= 10 
      split = JSON.parse(open("http://lingr.com/api/room/say?room=#{room}&bot=VimAdv&text=#{CGI.escape("合計 #{user.length}件\n#{user[0..9].join("\n")}")}&bot_verifier=f970a5aec3cbd149343aa5a4fec3a43e68d01e4a").read)
      return user[10..-1].join("\n")
    elsif user.length > 0
      return "合計 #{user.length}件\n#{user.join("\n")}"
    else
      data.map {|v|
        if /#{command[1]}/ =~ v[-1]["title"]
          result = JSON.parse(open("http://api.bit.ly/shorten?#{query[0]}#{v[-1]["url"]}#{query[1]}").read)
          search << "#{v[-1]["count"]} #{v[-1]["date"]} #{v[-1]["author"]} #{v[-1]["title"]} - #{result["results"][v[-1]["url"]]["shortUrl"]}"
        end
      }
      if search.length >= 10
        split = JSON.parse(open("http://lingr.com/api/room/say?room=#{room}&bot=VimAdv&text=#{CGI.escape("合計 #{search.length}件\n#{search[0..9].join("\n")}")}&bot_verifier=f970a5aec3cbd149343aa5a4fec3a43e68d01e4a").read)
        return search[10..-1].join("\n")
      elsif search.length > 0
        return "合計 #{search.length}件\n#{search.join("\n")}"
      end
    end
  end
end

docroot = "./doc"
jadocroot = "./ja-doc"
tags = File.read("#{docroot}/tags").lines.map {|l| l.chomp.split("\t", 3) }
agent = Mechanize.new

post '/vim' do
  content_type :text
  json = JSON.parse(request.body.string)
  json["events"].select {|e| e['message'] }.map {|e|
    m = e["message"]["text"]
    case m
    when /^(!VimAdv|:vimadv)/
      VimAdv(e)
    when /^:h(elp)?/
      Help(m,docroot,jadocroot,tags)
    when /^:vimhacks$/
      agent.get("http://vim-users.jp/category/vim-hacks/")
      return agent.page.search('h2 a').map{|e| "#{e.inner_text} - #{e['href']}"}[0,3].join("\n")
    when /^:vimhacks\s+?(\d+)\b/
      agent.get("http://vim-users.jp/hack#{$1}")
      return "#{agent.page.search('h1').inner_text} - #{agent.page.uri}"
    when /^:vimhacks\s+?(.*)\b/
      agent.get("http://vim-users.jp/?s=#{CGI.escape($1)}&cat=19")
      return agent.page.search('h2 a').map{|e| "#{e.inner_text} - #{e['href']}"}.select{|s| /hack/ =~ s}.join("\n")
    when /^またMacVimか$/
      return 'http://bit.ly/f2fjvZ#.png'
    when /SEGV/
      return "キャッシュ(笑)"
    else
      nil
    end
  }.compact.join
end
