module Parkaby
  class Generator < SexpProcessor
    include SexpTemplate
    
    template :main do
      _parkaby_buffer = [_parkaby_current = []]
      content!
      _parkaby_buffer.join
    end
    
    template :tag do
      _parkaby_current << "<#{name!}#{default!}#{attr!}>#{content!}</#{name!}>"
    end
    
    template :empty_tag do
      _parkaby_current << "<#{name!}#{default!}#{attr!}/>"
    end
    
    template :blocktag do
      _parkaby_current << "<#{name!}#{default!}#{attr!}>"

      _parkaby_buffer << (_parkaby_current = [])
      _parkaby_value = content!
      _parkaby_current << _parkaby_value if _parkaby_current.empty?

      _parkaby_current << "</#{name!}>"
    end
        
    template :otag do
      _parkaby_temp = content!
      
      if _parkaby_temp.is_a?(Hash)
        empty_tag(:name => name!,
                  :attr => attributes(:content => _parkaby_temp),
                  :default => default!)
      else
        tag(:name => name!,
            :attr => nil,
            :content => _parkaby_temp,
            :default => default!)
      end
    end
    
    template :text do
      _parkaby_current << content!
    end
    
    template :escape do
      content!.to_s.gsub(/[&<>"]/) { |s| Parkaby::ESCAPE_TABLE[s] }
    end
    
    template :attributes do
      content!.map { |k, v| " #{k}=\"#{escape(:content => v)}\""}.join
    end
    
    ## Initialize
    
    def initialize
      super
      self.auto_shift_type = true
    end
    
    ## Processors
    
    def process_parkaby(exp)
      type = exp.shift
      send("parkaby_#{type}", exp)
    end

    def parkaby_begin(exp)
      render :main, :content => process(exp.shift)
    end

    def parkaby_text(exp)
      render :text, :content => exp.shift
    end
    
    def parkaby_blocktag(exp)
      name = exp.shift
      data = exp.shift
      default = build_default(exp.shift)
      
      type = data.shift
      content = process(data.shift)
      attr = build_attr(data.shift)
      
      render :blocktag,
        :name    => name,
        :attr    => attr,
        :content => content,
        :default => default
    end
    
    def parkaby_tag(exp)
      name = exp.shift
      data = exp.shift
      default = build_default(exp.shift)
      
      type = data.shift
      
      case type
      when :data
        content = build_escape(data.shift)
        attr = build_attr(data.shift)
        template = content ? :tag : :empty_tag
        
        render template,
          :name => name, 
          :attr => attr,
          :content => content,
          :default => default
      when :odata
        content = data.shift
        
        render :otag,
          :name => name,
          :content => content,
          :default => default
      end
    end
    
    ## Builders
    
    def build_attr(exp)
      return unless exp.is_a?(Sexp)
      
      if exp.sexp_type == :hash
        exp.shift # remove :hash
        result = s(:dstr, string = '')
        
        until exp.empty?
          key = build_string(exp.shift)
          value = build_escape(exp.shift)
          string << " "
          
          if key.is_a? Sexp
            result << s(:evstr, key)
            result << s(:str, string = '')
          else
            string << key
          end
          
          string << '="'
          
          if value.is_a? Sexp
            result << s(:evstr, value)
            result << s(:str, string = '')
          else
            string << value
          end
          
          string << '"'
        end
        result
      else
        render :attributes, :content => exp
      end
    end
    
    def build_string(exp)
      case exp.sexp_type
      when :lit, :str
        exp[1].to_s
      else
        exp
      end
    end
    
    def build_escape(exp)
      return unless exp.is_a?(Sexp)
      case exp.sexp_type
      when :lit, :str
        teval :escape, :content => exp
      else
        render :escape, :content => exp
      end
    end
    
    def build_default(exp)
      type = exp.shift
      id = exp.shift
      classes = exp.shift
      
      str = ""
      
      str << " id=\"#{id.to_s.chomp("!")}\"" if id
      str << " class=\"#{classes.join(' ')}\"" unless classes.empty?
      
      str unless str.empty?
    end
    
    def teval(*args)
      sexp = render(*args)
      eval(Ruby2Ruby.new.process(sexp))
    end
  end
end