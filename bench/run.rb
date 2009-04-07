dir = File.dirname(__FILE__)
$:.unshift File.join(dir, '..', 'lib')
$:.unshift File.join(dir, '..', '..', 'haml', 'lib')

require 'benchmark'
require 'rubygems'
require 'markaby'
require 'parkaby'
require 'erubis'
require 'tagz'
require 'haml'

@obj = Object.new

def define_erb(content)
  Erubis::Eruby.new(content).def_method(@obj, :erubis)
  [['Erubis', '@obj.erubis']]
end

def define_mab(content)
  @park = Parkaby::Template.string(content)
  @cpark = @park.compile
  @park.def_method(@obj, :parkaby)
  eval("def @obj.parkaby_inline; Parkaby { #{content} }; end")
  @mark = Markaby::Template.new(content)
  [['Parkaby (def_method)', '@obj.parkaby'],
   ['Parkaby (render)', '@cpark.render'],
   ['Parkaby (inline)', '@obj.parkaby_inline'],
   ['Markaby', '@mark.render']]
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

Benchmark.bmbm(20) do |x|
  bench.each do |name, func|
    eval("x.report(#{name.inspect}){for i in 0..max;#{func};end}")
  end
end