require "parse_tree"
require "parse_tree_extensions"
require "unified_ruby"
require 'ruby2ruby'

class ArelConverter < Ruby2Ruby
  
  def self.translate(klass_or_str, method = nil)
    sexp = ParseTree.translate(klass_or_str, method)

    # unified_ruby is a rewriter plugin that rewires
    # the parse tree to make it easier to work with
    #  - defn arg above scope / making it arglist / ...
    unifier = Unifier.new
    unifier.processors.each do |p|
      p.unsupported.delete :cfunc # HACK
    end
    sexp = unifier.process(sexp)

    self.new.process(sexp)
  end
  
  
  def process_hash(exp)
    result = []
    
    if @conditions_hash
      result.push process_conditions_hash(exp)
      @conditions_hash = false
    else
  
      until exp.empty?
        lhs = process(exp.shift)
        rhs = exp.shift
        t = rhs.first
      
        @conditions_hash = (lhs == ':conditions' && t == :hash)
      
        rhs = process rhs
        rhs = "#{rhs}" unless [:lit, :str].include? t # TODO: verify better!
      
      
        result.push( hash_to_arel(lhs,rhs) )
      end
    end
    
    return result.join('.')
  end
  
  def hash_to_arel(lhs, rhs)
    case lhs
    when ':conditions'
      key = 'where'
    when ':include'
      key = 'includes'
    else
      key = lhs.sub(':','')
    end
    "#{key}(#{rhs})"
  end
  

  def process_conditions_hash(exp)
    result = []
    until exp.empty?
     lhs = process(exp.shift)
     rhs = exp.shift
     t = rhs.first
     rhs = process rhs
     rhs = "(#{rhs})" unless [:lit, :str, :true, :false].include? t # TODO: verify better!

     result << "#{lhs} => #{rhs}"
    end

    case self.context[1]
    when :arglist, :argscat then
     unless result.empty? then
       # HACK - this will break w/ 2 hashes as args
       if BINARY.include? @calls.last then
         return "{ #{result.join(', ')} }"
       else
         return "#{result.join(', ')}"
       end
     else
       return "{}"
     end
    else
     return "{ #{result.join(', ')} }"
    end
  end  
  
end