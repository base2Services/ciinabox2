require 'thor'
require 'fileutils'
require 'terminal-table'
require 'ciinabox/codebuild'

module Ciinabox
  module Jcasc 
    class Deploy < Thor::Group
      include Thor::Actions

      argument :name
      
      class_option :verbose, desc: 'set log level to debug', type: :boolean
      class_option :region, desc: 'AWS region'
      
      class_option :source_version, desc: 'commit to build', required: true
      class_option :wait, type: :boolean, default: true, desc: 'wait for build to complete'
      
      def set_aws_config
        Aws.config[:region] = options[:region] if options.has_key?('region')
      end
      
      def set_ciinabox_config
        @jenkins_config_file = "jenkins.yaml"
        @project_name = "#{name}-jcasc"
      end
      
      def trigger_build
        @build = Ciinabox::CodeBuild.new(@project_name)
        @build.trigger_build(options[:source_version],options[:wait])
      end
      
      def finish
        if @build.errors.any?
          say "Jenkins CasC update of #{options[:source_version]} failed with the following errors", :red
          table = Terminal::Table.new do |t|
            @build.errors.each do |e|
              t.add_row [e[:phase], e[:message].join(' ').gsub(/(.{1,#{150}})(\s+|\Z)/, "\\1\n")]
              t.add_separator
            end
            t.add_row ['Logs', @build.logs]
          end
          puts table
        else
          say "Jenkins CasC update of #{options[:source_version]} succeeded", :green
        end
      end
      
    end
  end
end