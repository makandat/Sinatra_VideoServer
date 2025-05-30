#!/usr/bin/env ruby
#  ビデオサーバ v2.2
require "sinatra"
require "cgi"

# 最初の１回だけ実行される。
configure do
  #set :bind, '0.0.0.0'
  #set :port, 9090
  set :environment, :production
  puts "<<< Sinatra ビデオサーバ v2.2 >>>"
end

# ヘルパメソッドの定義
helpers do
  # "folders.txt" を読んで配列として返す。
  def get_folders
    result = Array.new
    File.open("folders.txt") do |file|
      file.each_line do |line1|
        line = line1.strip
        unless line == ""
          result.push(line)
        end
      end
    end
    return result
  end
end

# root / の場合
get "/" do
  # folders.txt の内容
  list = get_folders
  @folders = ""
  list.each do |item|
    @folders += "<li><a href=\"/folder?dir=#{item}\">#{item}</a></li>\n"
  end
  @files = ""
  @path = ""
  @message = ""
  erb :index
end

# ファイル名が指定されたとき
get "/mp4/:filename" do
  @message = ""
  @path = ""
  # ファイル名を得る。
  filename = CGI.unescape(params[:filename])
  #puts filename
  # folders.txt の内容を読んで配列に格納する。
  folders = get_folders
  # そのファイルが存在するか確認
  folders.each do |folder|
    #puts folder
    path = folder
    path.tr!("\\", "/") if RUBY_PLATFORM =~ /win32|mingw|cygwin/
    path << "/#{filename}"
    if FileTest.exist?(path)
      puts "Send: " + path
      @path = path
      send_file path, :disposition => 'inline', :type => 'video/mp4'
      return
    #else
    #  puts "Skiped: " + path
    end
  end
  @message = "エラー： その画像ファイルは存在しない。"
end

# フルパスが指定されたとき
get "/path" do
  @message = ""
  # パス名を得る。
  path = CGI.unescape(params[:path])
  puts path
  if FileTest.exist?(path)
    puts "Send: " + path
    send_file path, :disposition => 'inline', :type => 'video/mp4'
  else
   @message = "'#{path}' does not exist."
  end
end

# 指定したフォルダ内の動画ファイル一覧を返す。
get "/folder" do
  puts "/folder"
  # フォルダ一覧
  list = get_folders
  @folders = ""
  list.each do |item|
    @folders += "<li><a href=\"/folder?dir=#{item}\">#{item}</a></li>\n"
  end
  # ファイル一覧
  @files = ""
  folder = params[:dir]
  files = Dir.entries(folder)
  files.each do |file|
    if file[0] == '.' || File.extname(file) != ".mp4"
      next
    end
    @files += "<li><a href=\"/mp4/#{file}\" target=\"_blank\">#{file}</a></li>\n"
  end
  erb :index
end

# その他の場合
not_found do
  "Bad route found!"
end
