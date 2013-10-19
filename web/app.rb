require 'rubygems'
require 'bundler'
Bundler.require

require 'pathname'
require 'tmpdir'

local_config = Pathname.new(__FILE__).dirname.join('config/local.rb')
load local_config if local_config.exist?

DataMapper.setup(:default, Local::DB)

class Script
  include DataMapper::Resource
  property :id, Serial, :key => true
  property :source, Text
  property :author, String, :index => true
  property :filename, String
  property :map_name, String, :index => true
  property :created_at, DateTime, :index => true

  has n, :matches, :through => Resource

  def map
    @map ||= Map.by_name(map_name)
  end

  def enqueue!
    QueuedScript.create(
      script: self,
      created_at: Time.now,
    )
  end
end

class Match
  include DataMapper::Resource
  property :id, Serial, :key => true
  property :map_name, String, :index => true
  belongs_to :winner, Script, :index => true

  has n, :contestants, Script, :through => Resource

  def self.run!(map, contestants)
    tmpdir = '/home/jay/tmp'
    script_paths = contestants.each_with_index.map do |script, i|
      fname = "#{tmpdir}/script#{i}.sh"
      source = script.source.gsub(/\r\n?/m, "\n")

      File.open(fname, 'w:UTF-8') { |f|
        f << source
      }

      fname
    end

    map.execute(script_paths)
  end

  def map
    @map ||= Map.by_name(map_name)
  end
end

class QueuedScript
  include DataMapper::Resource

  def self.peek
    QueuedScript.all(:order => [ :created_at.asc ]).first
  end

  property :id, Serial, :key => true
  belongs_to :script, Script
  property :created_at, DateTime, :index => true
end


DataMapper.finalize
DataMapper.auto_upgrade!

class Map
  ROOT = Pathname.new(__FILE__).dirname.parent
  MAPS = ROOT.join('share/maps')
  BIN = ROOT.join('bin/posix-wars')

  def self.all
    paths = MAPS.children
    paths.map { |p| new(p) }
  end

  def execute(script_paths)
    system("#{BIN.to_s} fight #{self.path.to_s} #{script_paths.join(' ')}")
  end

  def self.by_name(name)
    path = MAPS.join(name)
    raise "no such map" unless path.exist?
    new(path)
  end

  attr_reader :path
  def initialize(path)
    @path = path
  end

  def name
    path.basename
  end
end

class PosixWarsApp < Sinatra::Application
  get '/' do
    erb :index
  end

  post '/scripts' do
    script = Script.new(
      source: params[:source],
      author: params[:author],
      map_name: params[:map_name],
      filename: params[:filename],
      created_at: Time.now,
    )

    script.save

    script.enqueue!

    redirect "/scripts/#{script.id}"
  end

  get '/scripts/:id' do |id|
    @script = Script.get(id)
    @formatter = Rouge::Formatters::HTML.new
    @lexer = Rouge::Lexers::Shell.new
    erb :script
  end

  get '/maps/:map_name' do |map_name|
    all_scripts = Script.all(:map_name => map_name)

    @leaders = all_scripts.sort_by do |script|
      Match.count(winner: script)
    end.reverse.first(5)

    erb :leaderboard
  end
end
