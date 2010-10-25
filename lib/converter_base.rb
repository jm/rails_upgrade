module Rails
  module Converter
    class Base

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
          puts c.is_a?(Array) ? "#{YELLOW}\tFROM: #{c[0]}\n\t  TO: #{c[1]}" : "#{YELLOW}\t#{c[0]}"
        end
      ensure
        puts "#{CLEAR}"
      end
      
    end
  end
end