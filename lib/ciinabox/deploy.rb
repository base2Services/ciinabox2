require 'thor'
require 'ciinabox/utils'
require 'ciinabox/cfhighlander/stack'
require 'yaml'

module Ciinabox
  class Deploy < Thor::Group
    include Thor::Actions

    argument :name

    class_option :profile, desc: 'AWS Profile'
    class_option :region, default: ENV['AWS_REGION'], desc: 'AWS Region'

    def self.source_root
      File.dirname(__FILE__)
    end

    def load_config
      @build_dir = '.build'
      @ciinabox_config = "#{name}.ciinabox.yaml"
      @ciinabox = YAML.load(File.read(@ciinabox_config))
      puts "#{@ciinabox}"
      Aws.config[:profile] = options[:profile] if options.key?(:profile)
      Aws.config[:region] = @ciinabox[:region]
    end

    def generate_cfhiglander_stack
      remove_dir @build_dir
      empty_directory @build_dir
      template('templates/ciinabox.cfhighlander.rb.tt', "#{@build_dir}/#{name}.cfhighlander.rb")
      template('templates/default.config.yaml.tt', "#{@build_dir}/#{name}.config.yaml")
      cf_stack = Ciinabox::CfHiglander::Stack.new(@ciinabox, @build_dir)
      cf_stack.deploy()
    end

  end
end
