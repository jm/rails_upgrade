module Rails
  module Converter
    class NamedScope

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
  
      def contruct_for_arel(options)
        options.map do |key,value|
          case key
          when :conditions, :where
            key = 'where'
          when :include
            key = 'includes'
          end
          case
          when value.is_a?(Array)
            value = value.inspect
          when value.is_a?(Hash)
            value = value.inspect
          when value.is_a?(Symbol)
            value = ":#{value}"
          when value.is_a?(String) && key != 'where'
            value = %Q{"#{value}"}
          end
          "#{key}(#{value})"
        end
      end
      
      # Terminal colors, borrowed from Thor
      CLEAR      = "\e[0m"
      BOLD       = "\e[1m"
      RED        = "\e[31m"
      YELLOW     = "\e[33m"
      CYAN       = "\e[36m"
      WHITE      = "\e[37m"

      # Show an upgrade alert to the user
      def alert(title, culprits, errors=nil)
        if Config::CONFIG['host_os'].downcase =~ /mswin|windows|mingw/
          basic_alert(title, culprits, errors)
        else
          color_alert(title, culprits, errors)
        end
      end

      # Show an upgrade alert to the user.  If we're on Windows, we can't
      # use terminal colors, hence this method.
      def basic_alert(title, culprits, errors=nil)
        puts "** " + title
        puts "\t** " + error if error
        Array(culprits).each do |c|
          puts "\t- #{c}"
        end
        puts
      end

      # Show a colorful alert to the user
      def color_alert(file, culprits, errors=nil)
        puts "#{RED}#{BOLD}#{file}#{CLEAR}"
        Array(errors).each do |error|
          puts "#{CYAN}#{BOLD}\t- #{error}#{CLEAR}"
        end
        Array(culprits).each do |c|
          puts "#{YELLOW}\t#{c}"
        end
      ensure
        puts "#{CLEAR}"
      end
      
    end
  end
end
