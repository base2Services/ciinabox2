require 'thor'
require 'yaml'

require 'ciinabox/cloudformation'
require 'ciinabox/cfhighlander'
require 'ciinabox/log'

module Ciinabox
  class Deploy < Thor::Group
    include Thor::Actions
    include Ciinabox::Log

    argument :name
    
    class_option :profile, desc: 'AWS Profile'
    class_option :region, default: ENV['AWS_REGION'], desc: 'AWS Region'
    class_option :verbose, desc: 'set log level to debug', type: :boolean
    class_option :force, desc: 'skip changeset verification', type: :boolean

    def self.source_root
      File.dirname(__FILE__)
    end

    def set_loglevel
      Log.logger.level = Logger::DEBUG if @options[:verbose]
    end

    def set_ciinabox_config
      @build_dir = '.build'
      @config_file = "ciinabox.yaml"
      @config = YAML.load(File.read(@config_file))
    end

    def set_aws_config
      Aws.config[:profile] = options[:profile] if options.key?(:profile)
      Aws.config[:region] = @options[:region]
    end

    def generate_templates
      remove_dir @build_dir
      empty_directory @build_dir
      template('templates/ciinabox.cfhighlander.rb.tt', "#{@build_dir}/#{@name}.cfhighlander.rb")
      template('templates/default.config.yaml.tt', "#{@build_dir}/#{@name}.config.yaml")

      Log.logger.debug "Generating cloudformation from #{@build_dir}/#{@name}.cfhighlander.rb"
      cfhl = Ciinabox::CfHiglander.new(@options[:region],@name,@config,@build_dir)
      compiler = cfhl.render()
      @template_url = cfhl.publish(compiler)
    end

    def deploy_templates
      say "Launching cloudformation stack #{@name}-ciinabox in #{@options[:region]}"
      cfn = Ciinabox::Cloudformation.new(@name)
      change_set, change_set_type = cfn.create_change_set(@template_url)
      cfn.wait_for_changeset(change_set.id)
    
      if !@options[:force]
        changes = cfn.get_change_set(change_set.id)
    
        say "The following changes to the #{@name}-ciinabox stack will be made", :yellow
        changes.changes.each do |change|
          say "ID: #{change.resource_change.logical_resource_id} Action: #{change.resource_change.action}"
          change.resource_change.details.each do |details|
            say "Name: #{details.target.name} Attribute: #{details.target.attribute} Cause: #{details.causing_entity}"
          end
        end
    
        continue = yes? "\n\nContinue?", :green
        if !continue
          say "Cancelled cinabox deploy #{@name}", :red
          exit 1
        end
      else
        say "Forced change set approval", :yellow
      end
    
      cfn.execute_change_set(change_set.id)
      say "Waiting for #{change_set_type.downcase} to complete..."
      cfn.wait_for_execute(change_set_type)
    end
    
    
    
    def finish
      say "ciinabox deploy #{@name} complete,\nJenkins URL: https://jenkins.#{@name}.#{@config['root_domain']}"
    end

  end
end
