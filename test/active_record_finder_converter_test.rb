require 'test_helper'
require 'active_record_finder_converter'
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

class ActiveRecordFinderConverterTest < ActiveSupport::TestCase
  def setup
    @converter = Rails::Converter::ActiveRecordFinder.new
    @old_dir = Dir.pwd

    Dir.chdir(BASE_ROOT)
  end

  def test_convert_straight_find_all
    converted = @converter.process_line('Post.find(:all)')

    assert_equal converted, "Post.all"
  end

  def test_convert_straight_find_first
    converted = @converter.process_line('Post.find(:first)')

    assert_equal converted, "Post.first"
  end

  def test_convert_all_without_conditions
    converted = @converter.process_line("@model = Model.all(:select => 'column', :group => 'group_column', :order => 'created_at DESC')")

    assert_equal converted, '@model = Model.select("column").group("group_column").order("created_at DESC")'
  end

  def test_convert_all_with_conditions_array
    converted = @converter.process_line("@model = Model.all(:conditions => ['column IS NOT NULL'])")

    assert_equal converted, '@model = Model.where(["column IS NOT NULL"])'
  end

  def test_convert_all_with_conditions_string
    converted = @converter.process_line("@model = Model.all(:conditions => 'column IS NOT NULL')")

    assert_equal converted, '@model = Model.where("column IS NOT NULL")'
  end

  def test_convert_all_with_conditions_hash
    converted = @converter.process_line("@model = Model.all(:conditions => {:status => 'active', :current_user_id => current_user, :enabled => true})")

    assert_equal converted, '@model = Model.where({ :status => "active", :current_user_id => (current_user), :enabled => true })'
  end

  def test_convert_first_without_conditions
    converted = @converter.process_line("@model = Model.first(:select => 'column', :group => 'group_column', :order => 'created_at DESC')")

    assert_equal converted, '@model = Model.select("column").group("group_column").order("created_at DESC").first'
  end

  def test_convert_first_with_conditions_array
    converted = @converter.process_line("@model = Model.first(:conditions => ['column IS NOT NULL'])")

    assert_equal converted, '@model = Model.where(["column IS NOT NULL"]).first'
  end

  def test_convert_first_with_conditions_string
    converted = @converter.process_line("@model = Model.first(:conditions => 'column IS NOT NULL')")

    assert_equal converted, '@model = Model.where("column IS NOT NULL").first'
  end

  def test_convert_first_with_conditions_hash
    converted = @converter.process_line("@model = Model.first(:conditions => {:status => 'active', :current_user_id => current_user, :enabled => true})")

    assert_equal converted, '@model = Model.where({ :status => "active", :current_user_id => (current_user), :enabled => true }).first'
  end

  def test_convert_find_all_without_conditions
    converted = @converter.process_line("@model = Model.find(:all, :select => 'column', :group => 'group_column', :order => 'created_at DESC')")

    assert_equal converted, '@model = Model.select("column").group("group_column").order("created_at DESC")'
  end

  def test_convert_find_all_with_conditions_array
    converted = @converter.process_line("@model = Model.find(:all, :conditions => ['column IS NOT NULL'])")

    assert_equal converted, '@model = Model.where(["column IS NOT NULL"])'
  end

  def test_convert_find_all_with_conditions_string
    converted = @converter.process_line("@model = Model.find(:all, :conditions => 'column IS NOT NULL')")

    assert_equal converted, '@model = Model.where("column IS NOT NULL")'
  end

  def test_convert_find_all_with_conditions_hash
    converted = @converter.process_line("@model = Model.find(:all, :conditions => {:status => 'active', :current_user_id => current_user, :enabled => true})")

    assert_equal converted, '@model = Model.where({ :status => "active", :current_user_id => (current_user), :enabled => true })'
  end
  
  def test_convert_all_with_braced_conditions
    converted = @converter.process_line("@model = Model.all({:conditions => {:status => 'active'}})")

    assert_equal converted, '@model = Model.where({ :status => "active" })'
  end

  def test_convert_find_all_with_braced_conditions
    converted = @converter.process_line("@model = Model.find(:all, {:conditions => {:status => 'active'}})")

    assert_equal converted, '@model = Model.where({ :status => "active" })'
  end

  def test_convert_keeps_chained_methods
    converted = @converter.process_line("@model = Model.find(:all, :conditions => {:status => 'active'}).map(&:name)")

    assert_equal converted, '@model = Model.where({ :status => "active" }).map(&:name)'
  end

  def test_convert_all_with_single_argument
    assert_raise SyntaxError do
      @converter.process_line("@model = Model.all(conditions_hash)")
    end
  end
  
  def test_convert_raises_when_line_is_incomplete
    assert_raise RuntimeError do
      @converter.process_line("@model = Model.find(:all,")
    end
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