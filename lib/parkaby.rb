$:.unshift File.dirname(__FILE__)

require 'rubygems'
require 'parse_tree'
require 'parse_tree_extensions'
require 'ruby_parser'
require 'ruby2ruby'

module Parkaby
  autoload :Processor,         'parkaby/processor'
  autoload :Generator,         'parkaby/generator'
  autoload :Template,          'parkaby/template'
  autoload :CompiledTemplate,  'parkaby/template'
  autoload :CompiledProcTemplate,  'parkaby/template'
  autoload :CompiledStringTemplate,  'parkaby/template'
  
  module Frameworks
    autoload :Camping, 'parkaby/frameworks/camping'
    autoload :Sinatra, 'parkaby/frameworks/sinatra'
    autoload :Rails,   'parkaby/frameworks/rails'
  end
  
  ESCAPE_TABLE = {
    '&' => '&amp;',
    '<' => '&lt;',
    '>' => '&gt;',
    '"' => '&quot;',
    "'" => '&#039;',
  }
end

def Parkaby(&blk)
  Parkaby::Template.compile_block(&blk).render(blk)
end
