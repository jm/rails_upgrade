require 'test_helper'
require 'named_scope_converter'
require 'fileutils'

tmp_dir = "#{File.dirname(__FILE__)}/fixtures/tmp"

if defined? BASE_ROOT
  BASE_ROOT.replace tmp_dir
else
  BASE_ROOT = tmp_dir
end
FileUtils.mkdir_p BASE_ROOT

# Stub out methods on converter class
module Rails
  module Converter
    class Base
      attr_reader :alerts

      def alert(title, text, more_info_url, culprits)
        @alerts[title] = [text, more_info_url, culprits]
      end
    end
  end
end

class NamedScopeTest < ActiveSupport::TestCase
  def setup
    @converter = Rails::Converter::NamedScope.new
    @old_dir = Dir.pwd

    Dir.chdir(BASE_ROOT)
  end

  def test_convert_lambda
    converted = @converter.process_line('named_scope :for_brokers, lambda{|brokers| {:conditions => ["broker_id IN (?)", brokers.map(&:id)]}}')

    assert_equal converted, 'scope :for_brokers, lambda{|brokers| where(["broker_id IN (?)", brokers.map(&:id)])}'
  end

  def test_convert_normal
    converted = @converter.process_line("named_scope :imported, :conditions => 'momex_user_id IS NOT NULL'")

    assert_equal converted, 'scope :imported, where("momex_user_id IS NOT NULL")'
  end

 
  def teardown
    clear_files

    Dir.chdir(@old_dir)
  end

  def make_file(where, name=nil, contents=nil)
    FileUtils.mkdir_p "#{BASE_ROOT}/#{where}"
    File.open("#{BASE_ROOT}/#{where}/#{name}", "w+") do |f|
      f.write(contents)
    end if name
  end

  def clear_files
    FileUtils.rm_rf(Dir.glob("#{BASE_ROOT}/*"))
  end
end