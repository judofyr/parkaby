module Parkaby::Frameworks::Camping
  def self.included(mod)
    mod.module_eval %q{
      include(CompiledViews = Module.new {
        include Views
      })
      
      def render(m)
        parkaby(m, m.to_s[0] != ?_)
      end

      def parkaby(method, layout, &blk)
        parkify(method) unless parkified?(method)
        s = send(method, &blk)
        s = parkaby(:layout, false) { s } if layout
        s
      end

      def parkified?(method)
        CompiledViews.instance_methods(false).include?(method.to_s)
      end
  
      def parkify(method)
        # method(method).to_sexp is broken
        sexp = ParseTree.translate(Views, method)
        sexp = Unifier.new.process(sexp)
        temp = Parkaby::Template.new(sexp[3])
        temp.def_method(CompiledViews, method)
      end
    }
  end
end