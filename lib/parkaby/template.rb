module Parkaby
  class Template
    @cache = {}
    
    class << self
      def string(str)
        Parkaby.load 'ruby_parser', 'RubyParser' do
          def string(str)
            new(RubyParser.new.parse(str))
          end
          string(str)
        end
      end
      
      def compile_block(&blk)
        @cache[blk.to_s] ||= block(&blk).compile(blk)
      end
      
      def block(&blk)
        Parkaby.load 'parse_tree', 'ParseTree' do
          def block(&blk)
            new(Parkaby.proc_to_sexp(blk)[3])
          end
          block(&blk)
        end
      end
    end
    
    def initialize(sexp)
      @sexp = sexp
    end
    
    def def_method(obj, meth, force_type = nil)
      force_type ||= obj.is_a?(Module) ? :module_eval : :instance_eval
      obj.send(force_type, "def #{meth};#{to_ruby(obj)};end")
    end

    def compile_as_string(b = nil)
      CompiledStringTemplate.new(to_ruby(b))
    end
    
    def compile_as_proc(obj = nil)
      CompiledProcTemplate.new(to_ruby(obj))
    end
    
    def compile(helper = nil)
      if helper.is_a?(Binding) || helper.is_a?(Proc)
        compile_as_string(helper)
      else
        compile_as_proc(helper)
      end
     end
    
    def to_ruby(helper = nil)
      Ruby2Ruby.new.process(to_sexp(helper))
    end
    
    def to_sexp(helper = nil)
      if helper.is_a?(Binding) || helper.is_a?(Proc)
        helper = eval("self", helper)
      end
      processor = Processor.new(helper)
      sexp = processor.build(sexp())
      Generator.new.process(sexp)
    end
    
    private
    
    def sexp
      Marshal.load(Marshal.dump(@sexp))
    end
  end
  
  class CompiledTemplate
    attr_reader :code
    
    def initialize(code)
      @code = code
    end
    
    def render
      raise 'Please use CompiledProcTemplate or CompiledStringTemplate'
    end
  end
  
  class CompiledProcTemplate < CompiledTemplate
    def initialize(code)
      super
      @proc = eval("proc{#{code}}")
    end
    
    def render(obj = nil)
      if obj
        if obj.is_a?(Binding) || obj.is_a?(Proc)
          obj = eval("self", obj)
        end
        obj.instance_eval(&@proc)
      else
        @proc.call
      end
    end
  end
  
  class CompiledStringTemplate < CompiledTemplate 
    def render(obj = nil)
      if obj
        unless obj.is_a?(Binding) || obj.is_a?(Proc)
          obj = obj.instance_eval { binding }
        end
        eval(@code, obj)
      else
        eval(@code)
      end
    end
  end
end