require 'thor'
require 'fileutils'
require 'ciinabox/utils'
require 'ciinabox/fleet'

module Ciinabox
  class JenkinsConfig < Thor::Group
    include Thor::Actions

    argument :name

    class_option :profile, desc: 'AWS Profile'
    class_option :region, default: ENV['AWS_REGION'], desc: 'AWS Region'
    
    class_option :init, type: :boolean, default: false, desc: 'generate a jenkins configuration as code template'

    def self.source_root
      File.dirname(__FILE__)
    end

    def set_ciinabox_config
      @build_dir = '.build'
      @config_file = "#{@name}.ciinabox.yaml"
      @jenkins_config_file = "jenkins.yaml"
      @config = YAML.load(File.read(@config_file))
    end
    
    def init
      if !File.file?(@jenkins_config_file) || @options['init']
        opts = { region: @options['region']}
        template('templates/jenkins.yaml.tt', "jenkins.yaml", opts)
      end
    end

    def store_config
      Ciinabox::Utils.store_config(@config['source_bucket'],@name,@jenkins_config_file)
      say "uploaded jenkins.yaml config file to s3://#{@config['source_bucket']}/#{@name}/jenkins/jenkins.yaml"
    end
    
    def finish
      say "Go to https://jenkins.#{@name}.#{@config['root_domain']}/configuration-as-code/ to apply the changes"
    end
        
  end
end