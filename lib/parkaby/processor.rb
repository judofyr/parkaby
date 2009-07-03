module Parkaby
  class Processor < SexpProcessor
    # s(:begin,    exp)
    # s(:text,     exp)
    # s(:tag,      name, content, attr)
    # s(:blocktag, name, content, attr)
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

      self.require_empty = false
    end
    
    def build(sexp = nil, &blk)
      s(:parkaby, :begin, process(sexp, &blk))
    end
    
    def process(sexp = nil, &blk)
      if blk
        super(Parkaby.proc_to_sexp(blk)[3])   # Just a little helper for development
      else
        super(sexp)
      end
    end
    
    def process_call(exp)
      # exp[1] => reciever.
      # exp[2] => method
      # exp[3] => (args)
      exp[3] = process(exp[3])
      if text?(exp)
        s(:parkaby, :text, exp[3])
      elsif tag = force_tag_call?(exp) || tag_call?(exp)
        s(:parkaby, :tag, *tag)
      elsif follow = follow_call?(exp)
        s(:parkaby, :follow, exp)
      else
        exp
      end
    end
    
    def process_iter(exp)
      # exp[1] => process_call
      # exp[2] => |args|
      # exp[3] => {blk}
      exp[3] = process(exp[3])
      if tag = force_tag_iter?(exp) || tag_iter?(exp)
        s(:parkaby, :blocktag, *tag)
      else
        exp
      end
    end
    
    def tag_call?(exp)
      # Receiver must be nil
      exp[1].nil? and
      # It can't be defined on the helper
      !helper_respond_to?(exp[2]) and
      # The args must be correct
      args = tag_args?(exp[3]) and
      # It can't look like a text
      !like_text?(exp) and
      # Returns [method, content, attr]
      [exp[2], *args]
    end
    
    def tag_iter?(exp)
      # No block args
      exp[2].nil? and
      # The call must look like a call
      tag = tag_call?(exp[1]) and
      # It can't have both a block and content
      !tag[1] and
      # Returns [method, block, attr]
      [tag[0], exp[3], tag[2]]
    end
    
    def tag_args?(exp)
      case exp.length
      when 1
        # Empty tag. No content, no attr
        return []
      when 2
        if exp[1][0] == :hash
          # Only attr.
          return [nil, exp[1]]
        else
          # Something else = content.
          return [exp[1], nil]
        end
      when 3
        # If 2nd isn't a Hash, it's wrong.
        return false unless exp[2][0] == :hash
        return exp[1..2]
      end
    end
    
    def force_tag_call?(exp)
      # receiver must be "tag"
      exp[1] == s(:call, nil, :tag, s(:arglist)) and
      # args must be correct
      args = tag_args?(exp[3]) and
      [exp[2], *args]
    end
    
    def force_tag_iter?(exp)
      # The call must look like a forced tag!
      tag = force_tag_call?(exp[1]) and
      # Returns [method, block, attr]
      [tag[0], exp[3], tag[2]]
    end
    
    
    def follow_call?(exp)
      #exp[1] == s(:call, nil, :follow, s(:arglist))
      false
    end
    
    def like_text?(exp)
      rec_meth = exp[1..2].to_a
      rec_meth == [[:self], :<<] || rec_meth == [nil, :text]
    end
    
    def text?(exp)
      like_text?(exp) and
      exp[3].length == 2
    end
    
    def helper_respond_to?(meth)
      @helper.respond_to?(meth)
    end
  end
end