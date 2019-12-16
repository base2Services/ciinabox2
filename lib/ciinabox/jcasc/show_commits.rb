require 'thor'
require 'fileutils'
require 'terminal-table'
require 'ciinabox/codecommit'

module Ciinabox
  module Jcasc 
    class ShowCommits < Thor::Group
      include Thor::Actions

      argument :name
      
      class_option :verbose, desc: 'set log level to debug', type: :boolean
      class_option :region, desc: 'AWS region'

      def set_aws_config
        Aws.config[:region] = options[:region] if options.has_key?('region')
      end
      
      def set_ciinabox_config
        @jenkins_config_file = "jenkins.yaml"
        @repo_name = "#{name}-jcasc"
      end
      
      def display
        history = Ciinabox::CodeCommit.new(@repo_name).get_commit_history()
        puts Terminal::Table.new(:headings => history.first.keys, :rows => history.map {|h| h.values })
      end
      
    end
  end
end