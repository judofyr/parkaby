$:.unshift File.dirname(__FILE__)

require 'ruby2ruby'
require 'sexp_template'
require 'sexp_builder'

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
  
  class MissingDependency < StandardError
    def initialize(lib)
      @lib = lib
    end
    
    def to_s
      "#{@lib} is required. Please put in load path or require it yourself."
    end
  end
  
  def self.proc_to_sexp(blk)
    pt = ParseTree.new(false)
    sexp = pt.parse_tree_for_proc(blk)
    Unifier.new.process(sexp)
  end
  
  def self.load(lib, klass = nil)
    begin
      require lib unless klass && eval("defined?(#{klass})")
    rescue LoadError
      raise MissingDependency.new(lib)
    else
      yield if block_given?
    end
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
