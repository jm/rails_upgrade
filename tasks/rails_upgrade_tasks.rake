$:.unshift(File.dirname(__FILE__) + "/../lib")
require 'routes_upgrader'
require 'gemfile_generator'
require 'application_checker'
require 'new_configuration_generator'

namespace :rails do
  namespace :upgrade do
    desc "Runs a battery of checks on your Rails 2.x app and generates a report on required upgrades for Rails 3"
    task :check do
      checker = Rails::Upgrading::ApplicationChecker.new
      checker.run
    end
  
    desc "Generates a Gemfile for your Rails 3 app out of your config.gem directives"
    task :gems do
      generator = Rails::Upgrading::GemfileGenerator.new
      new_gemfile = generator.generate_new_gemfile
    
      puts new_gemfile
    end
  
    desc "Create a new, upgraded route file from your current routes.rb"
    task :routes do
      upgrader = Rails::Upgrading::RoutesUpgrader.new
      new_routes = upgrader.generate_new_routes
    
      puts new_routes
    end
    
    desc "Extracts your configuration code so you can create a new config/application.rb"
    task :configuration do
      upgrader = Rails::Upgrading::NewConfigurationGenerator.new
      new_config = upgrader.generate_new_application_rb
      
      puts new_config
    end
  end
end