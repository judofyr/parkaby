dir = File.dirname(__FILE__)
$:.unshift File.join(dir, '..', 'lib')
$:.unshift File.join(dir, '..', '..', 'haml', 'lib')

require 'benchmark'
require 'rubygems'
require 'markaby'
require 'parkaby'
require 'erubis'
require 'erb'
require 'tagz'
require 'haml'
require 'erector'
require 'nokogiri'
include Erector::Mixin

@obj = Object.new

def define_erb(content)
  Erubis::Eruby.new(content).def_method(@obj, :erubis)
  @obj.extend(ERB.new(content).def_module)
  [['Erubis', '@obj.erubis'],
   ['ERB', '@obj.erb']]
end

def define_mab(content)
  @park = Parkaby::Template.string(content)
  @cpark = @park.compile
  @park.def_method(@obj, :parkaby)
  eval("def @obj.parkaby_inline; Parkaby { #{content} }; end")
  eval("def @obj.erector_inline; erector { #{content} }; end")
  eval("def @obj.nokogiri_inline; Nokogiri::HTML::Builder.new { #{content.gsub('text', 'cdata')} }.to_html; end")
  @mark = Markaby::Template.new(content)
  [['Parkaby (def_method)', '@obj.parkaby'],
   ['Parkaby (render)', '@cpark.render'],
   ['Parkaby (inline)', '@obj.parkaby_inline'],
   ['Markaby', '@mark.render'],
   ['Erector', '@obj.erector_inline'],
   ['Nokogiri', '@obj.nokogiri_inline']]
end

def define_tagz(content)
  eval("def @obj.tagz; Tagz { #{content} }; end")
  [['Tagz', '@obj.tagz']]
end

def define_haml(content)
  Haml::Engine.new(content, :ugly => true).def_method(@obj, :haml)
  [['Haml', '@obj.haml']]
end

name = ARGV[0]
max = ARGV[1].to_i

bench = Dir["#{dir}/#{name}.*"].inject([]) do |m, f|
  ext = File.extname(f)[1..-1]
  m + send("define_#{ext}", File.read(f))
end

if max.zero?
  result = []
  
  bench.each do |name, func|
    result << [name, eval(func)]
    puts " #{name} ".center(30, "-")
    puts result[-1][1]
  end
  
  exit
end

Benchmark.bmbm(20) do |x|
  bench.each do |name, func|
    eval("x.report(#{name.inspect}){for i in 0..max;#{func};end}")
  end
end