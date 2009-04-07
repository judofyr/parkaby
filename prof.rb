#! /usr/bin/env ruby

require 'rubygems'
require 'ruby-prof'

$:.unshift File.join(File.dirname(__FILE__), 'lib')

require 'parkaby'

park = Parkaby::Template.string(File.read("bench/nasty.mab"))
cpark = park.compile

RubyProf.start

500.times do ||
  cpark.render
end


result = RubyProf.stop

printer = RubyProf::GraphHtmlPrinter.new(result)
printer.print(STDOUT, '1')
