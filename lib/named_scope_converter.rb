$:.unshift(File.dirname(__FILE__) + "/../../lib")
require 'converter_base'

module Rails
  module Converter
    class NamedScope < Base

      def run
        Dir['app/models/**/*'].each do |file|
          begin
            parse_file(file)
          rescue => e
            alert(file, new_scopes, e.message)
          end
        end
      end

      def parse_file(file)
        raw_named_scopes = `grep -r 'named_scope' #{file}`

        return if raw_named_scopes == ''
    
        failures = []
        lambda_regex = /lambda\s*\{\|(.*?)\|\s*\{(.*?)\}\s*\}$/
    
        named_scopes = raw_named_scopes.split("\n")
        new_scopes = named_scopes.map do |scope|
          scope.strip!
          if scope =~ /^[\s#]*named/
            new_scope = scope.split(",").first.gsub('named_scope','scope')
            matches = lambda_regex.match(scope.strip)

            begin  
              params = matches ? parse_lambda(matches) : parse_normal(scope)
              "#{new_scope}, #{params}"
            rescue SyntaxError => e
              failures << "SyntaxError when evaluatiing options for #{scope}"
              nil
            rescue => e
              failures << "#{e.class} #{e.message} when evaluatiing options for #{scope}"
              nil
            end
          end
        end.compact
        alert(file, new_scopes, failures) unless (new_scopes.nil? || new_scopes.empty?) && failures.empty?
      end
  
      def parse_lambda(matches)
        case
        when  conditions = /:conditions =>\s?\[(.*?)\](,|\})?/.match(matches[2]),
              conditions = /:conditions =>\s?\{(.*?)\}/.match(matches[2]),
              conditions = /:conditions =>\s?(.*?)\}/.match(matches[2])
          where = conditions[1]
        else
          raise RuntimeError, "Can't find :conditions in #{matches[0]}"
          where = nil
        end          
    
        hash = matches[2].gsub(conditions[0],'').strip.gsub(/,$/, '')
        options = {}
        options = eval("{#{hash}}")  if hash
        options[:where] = where if where
        options
    
        "lambda { |#{matches[1]}| #{contruct_for_arel(options).join('.')}}"
      end
  
      def parse_normal(scope)
        options = %Q{#{scope.gsub(/^.*?,/, '').strip}} 
        options = %Q{{#{options}}} unless options =~ /^\{.*\}$/
        contruct_for_arel(eval(options)).join('.')
      end
        
    end
  end
end
