require 'pathname'

load Pathname.new(__FILE__).dirname.join('app.rb')

run PosixWarsApp
