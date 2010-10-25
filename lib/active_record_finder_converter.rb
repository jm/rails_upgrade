$:.unshift(File.dirname(__FILE__) + "/../../lib")
require 'converter_base'
require 'arel_converter'

module Rails
  module Converter
    class ActiveRecordFinder < Base
      
      def run
        Dir['app/**/*'].each do |file|
          begin
            parse_file(file) unless File.directory?(file)
          rescue => e
            alert(file, [], e.message)
          end
        end
      end

      def parse_file(file)
        raw_ar_finders = ''
        ["find(:all", "find(:first", "find.*:conditions =>", ":joins =>"].each do |v|
          raw_ar_finders += `grep -r '#{v}' #{file}`
        end
        ar_finders = raw_ar_finders.split("\n").uniq.reject {|l| l.include?('named_scope') }
        
        unless ar_finders.empty?

          failures = []
          find_regex = /find\(:all,(.*)\)$/
          embedded_find_regex = /find\(:all,(.*?)\)\./

          new_ar_finders = ar_finders.map do |ar_finder|
            ar_finder.strip!
            begin 
              sexp = ParseTree.new.process(ar_finder)
              processed = ArelConverter.new.process(sexp)
              clean = /find\(:(all|first), (.*?)\)\)/.match(processed)
              case clean[1]
              when 'all'
                processed.gsub!(/find\(:all, (.*?)\)\)/, "#{clean[2]})") 
              when 'first'
                processed.gsub!(/find\(:first, (.*?)\)\)/, "#{clean[2]}).first") 
              else
                raise RuntimeError, "don't know how to handle #{clean[1]}"
              end
              [ar_finder,processed]
            rescue SyntaxError => e
              failures << "SyntaxError when evaluatiing options for #{ar_finder}"
              nil
            rescue => e
              failures << "#{e.class} #{e.message} when evaluatiing options for #{ar_finder}\n#{e.backtrace.first}"
              nil
            end
          end.compact
          alert(file, new_ar_finders, failures) unless (new_ar_finders.nil? || new_ar_finders.empty?) && failures.empty?
        end
      end
    end
  end
end