module Parkaby
  class Generator < Ruby2Ruby
    P = "_parkaby_buffer"
    PC = "_parkaby_current"
    PV = "_parkaby_value"

    INIT_PC = "#{PC} = []"
    PRE = "#{P} = [#{INIT_PC}]\n"
    POST = "\n#{P}.join"

    BEFORE_BLOCK = %{#{P} << (#{INIT_PC})\n}
    BLOCK = %{#{PV} = begin\n%s\nend\n}
    AFTER_BLOCK = %{#{PC} << #{PV} if #{PC}.empty?\n}

    ESCAPE = %q{(%s).to_s.gsub(/[&<>"]/) { |s| Parkaby::ESCAPE_TABLE[s] }}

    def process_parkaby(exp)
      type = exp.shift
      send("parkaby_#{type}", exp)
    end

    def parkaby_begin(exp)
      PRE + process(exp.shift) + POST
    end

    def parkaby_text(exp)
      value = exp.shift
      "#{PC} << #{process(value)}"
    end

    def parkaby_tag(exp)
      name = build_name(exp.shift)
      content = exp.shift
      attr = exp.shift

      result = build_open(name, attr, content.nil?)

      if content
        result << "#{build_escape(content)}</#{name}>"
      end

      "#{PC} << \"#{result}\"\n"
    end

    def parkaby_blocktag(exp) 
      result = []
      name = build_name(exp.shift)
      content = exp.shift
      attr = exp.shift

      result << "#{PC} << \"#{build_open(name, attr)}\""
      
      result << BEFORE_BLOCK
      result << BLOCK % process(content)
      result << AFTER_BLOCK

      result << "#{PC} << '</#{name}>'"
      result * $/ + $/
    end
    
    def build_name(name)
      case name
      when Sexp
        build_string(name)
      else
        name.to_s
      end
    end

    def build_open(name, attr, close = false)
      e = '/' if close
      if attr.nil?
        "<#{name}#{e}>"
      else
        "<#{name} #{build_attr(attr)}#{e}>"
      end
    end
    
    # Builds the attributes.
    def build_attr(attr)
      attr.shift # remove :hash
      result = []
      until attr.empty?
        key = attr.shift
        value = attr.shift
        result << build_string(key) + '=\"' + build_escape(value) + '\"'
      end
      result * " "
    end

    # Builds a string which can be put directly into another string.
    def build_string(exp)
      case exp[0]
      when :lit, :str
        exp[1].to_s
      when :dstr
        process(exp)[1..-2]
      else
        '#{' + process(exp) + '}'
      end
    end
    
    # Builds an escaped string which can be put directly into another string.
    def build_escape(exp)
      case exp[0]
      when :lit, :str
        eval(ESCAPE % process(exp))
      else
        '#{' + ESCAPE % process(exp) + '}'
      end
    end
  end
end