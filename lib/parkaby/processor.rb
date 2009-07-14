module Parkaby
  class Processor < SexpBuilder
    # s(:begin,    exp)
    # s(:text,     exp)
    # s(:tag,      name, :data, :default)
    # s(:blocktag, name, :data, :default)
    # s(:data,     content, attr)
    # s(:odata,    content_or_attr) # have to check at runtime
    # s(:default,  id, classes)
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
    
    # Builds the basic tag_call, which allows variations in the arglist
    rule :tag_call_builder do |args|
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
    

    # Matches a tag_call with no arguments.  Used in CSS Proxy.
    rule :empty_tag_call do
      tag_call_builder(s(:arglist))
    end
    
    rule :class_name do
      m(/[^!]$/) % :class
    end
    
    rule :id do
      m(/!$/) % :id
    end
    
    # Recursively matches tag.klass.klass.klass
    rule :empty_class_proxy do
      empty_tag_call |
      s(:call,
        empty_class_proxy,
        class_name,
        s(:arglist))
    end
    
    # Matches empty_class_proxy.id!(args)
    #     and empty_class_proxy.klass(args)
    rule :css_proxy do |args|
      s(:call,
        empty_class_proxy,
        id | class_name,
        args % :css_args)
    end

    rule :tag_call do
      n(scope(:call)) &
      (tag_call_builder(args_call) |
       css_proxy(args_call))
    end

    rule :tag_iter do
      n(scope(:call)) &
      s(:iter,
       tag_call_builder(args_iter) | css_proxy(args_iter),
       nil,
       wild % :content)
    end

    rule :text do
      s(:call, nil,      :text, s(:arglist, wild % :content)) |
      s(:call, s(:self), :<<,   s(:arglist, wild % :content))
    end

    ## Rewriters   

    rewrite :tag_call do |data|
      # Find classes and ids
      default = s(:default, data[:id], Array(data[:class]))
      # Process args using custom method
      args = process_args_call(data[:css_args] || data[:args])
      s(:parkaby, :tag, data[:name], args, default)
    end

    rewrite :tag_iter do |data|
      # Find classes and ids
      default = s(:default, data[:id], Array(data[:class]))
      # Process args using custom method
      args = process_args_iter(data[:css_args] || data[:args])
      # Inject the content into the data-node:
      args[1] = process(data[:content])
      s(:parkaby, :blocktag, data[:name], args, default)
    end

    rewrite :text do |data|
      # In this specific case we don't need to process the arglist.
      s(:parkaby, :text, data[:content])
    end
    
    def process_args_call(exp)
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

    def process_args_iter(exp)
      case exp.length
      when 1
        s(:data, nil, nil)
      when 2
        # Content is given as block, must be attr
        s(:data, nil, exp[1])
      end
    end
  end
end