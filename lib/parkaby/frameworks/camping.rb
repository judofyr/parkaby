Parkaby.load('parse_tree', 'ParseTree')

# == Using it
#
#   module Blog
#     include Parkaby::Frameworks::Camping 
#     
#     def self.create
#       Views.compile!
#     end
#   end
module Parkaby::Frameworks::Camping
  class Processor < SexpProcessor
    def initialize(*a)
      super
      self.require_empty = false
    end
    
    def process_call(exp)
      if partial?(exp)
        s(:call, nil, :text, s(:arglist, exp))
      else
        exp
      end
    end
    
    def partial?(exp)
      exp[1].nil? &&
      exp[2].to_s[0] == ?_
    end
  end
  
  def self.included(mod)
    mod.module_eval %q{
      include(CompiledViews = Module.new {
        include Views
      })
      
      module Views
        def self.compile!
          instance_methods(false).each do |method|
            compile_method(method)
          end
        end
        
        def self.compile_method(method)
          sexp = ParseTree.translate(Views, method)
          sexp = Unifier.new.process(sexp)
          sexp = Parkaby::Frameworks::Camping::Processor.new.process(sexp)
          sexp[3] = Parkaby::Processor.new(Views).build(sexp[3])
          sexp = Parkaby::Generator.new.process(sexp)
          ruby = Ruby2Ruby.new.process(sexp)
          CompiledViews.class_eval(ruby)
        end
      end
      
      def render(m)
        parkaby(m, m.to_s[0] != ?_)
      end

      def parkaby(method, layout, &blk)
        s = send(method, &blk)
        s = parkaby(:layout, false) { s } if layout
        s
      end
    }
  end
end