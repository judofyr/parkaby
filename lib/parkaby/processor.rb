module Parkaby
  class Processor < SexpBuilder
    # s(:begin,    exp)
    # s(:text,     exp)
    # s(:tag,      name, :data)
    # s(:blocktag, name, :data)
    # s(:data,     content, attr)
    # s(:odata,    content_or_attr) # have to check at runtime
    # s(:follow,   call)   # NOT IMPLEMENTED YET
    def initialize(helper = nil)
      super()

      @helper = case helper
      when Class
        helper.allocate
      when Module
        Class.new { include helper }.allocate
      else
        helper
      end
    end
    
    def build(sexp = nil, &blk)
      s(:parkaby, :begin, process(sexp, &blk))
    end
    
    def helper_respond_to?(meth)
      @helper.respond_to?(meth)
    end
    
    ## Matchers
    
    matcher :name do |name|
      !helper_respond_to?(name)
    end

    matcher :args_call do |exp|
      exp.length < 4
    end

    matcher :args_iter do |exp|
      exp.length < 3
    end

    ## Rules

    rule :tag_call_builder do |iter|
      # If iter is true, use the args_iter-mather,
      # If not,          use the args_call-matcher
      args = iter ? args_iter : args_call

      # Forced tag call
      s(:call,
       s(:call, nil, :tag, s(:arglist)),
       wild % :name,
       args % :args) |  # <- args-matcher

      # or regular tag call
      s(:call,
       nil,
       name % :name,
       args % :args)    # <- args-matcher
    end

    rule :tag_call do
      tag_call_builder(false)
    end

    rule :tag_iter do
      s(:iter,
       tag_call_builder(true),  # <- pass true so we use the args_iter matcher
       nil,
       wild % :content)
    end

    rule :text do
      s(:call, nil,      :text, s(:arglist, wild % :content)) |
      s(:call, s(:self), :<<,   s(:arglist, wild % :content))
    end

    ## Rewriters
    
    rewrite :in => :args_call do |data|
      exp = data.sexp
      case exp.length
      when 1
        s(:data, nil, nil)
      when 2
        case exp[1].sexp_type
        when :hash
          s(:data, nil, exp[1])
        when :str, :lit
          s(:data, exp[1], nil)
        else
          # Could be both a content or attr
          s(:odata, exp[1])
        end
      when 3
        s(:data, exp[1], exp[2])
      end
    end

    rewrite :in => :args_iter do |data|
      exp = data.sexp
      case exp.length
      when 1
        s(:data, nil, nil)
      when 2
        # Content is given as block, must be attr
        s(:data, nil, exp[1])
      end
    end    

    rewrite :tag_call do |data|
      # Process args in the args-context
      s(:parkaby, :tag, data[:name], process_args_call(data[:args]))
    end

    rewrite :tag_iter do |data|
      # Process args in the args-context
      args = process_args_iter(data[:args])
      # Inject the content into the data-node:
      args[1] = process(data[:content])
      s(:parkaby, :blocktag, data[:name], args)
    end

    rewrite :text do |data|
      # In this specific case we don't need to process the arglist.
      s(:parkaby, :text, data[:content])
    end
  end
end