require 'thor'
require 'time'
require 'fileutils'
require 'ciinabox/s3'

module Ciinabox
  module Jcasc 
    class S3File < Thor::Group
      include Thor::Actions

      argument :name
      
      class_option :verbose, desc: 'set log level to debug', type: :boolean
      class_option :region, desc: 'AWS region', default: ENV['AWS_REGION']
      class_option :print, desc: 'print the Jenkins CasC file to stdout', type: :boolean

      def set_aws_config
        if !options.has_key?('region')
          error "unable to find region from --region or ENV['AWS_REGION']"
          exit 1
        end
        Aws.config[:region] = options[:region] 
      end
            
      def self.source_root
        File.dirname(__FILE__)
      end

      def set_ciinabox_config
        @build_dir = '.build'
        @jenkins_config_file = "jenkins.yaml"
        @bucket = "jcasc.#{name}.#{options[:region]}.#{Utils.aws_account_id()}"
      end
      
      def get_config_file
        s3 = Ciinabox::S3.new(@bucket)
        @object = s3.get_object("#{name}/#{@jenkins_config_file}")
      end
      
      def display
        if options[:print]
          puts @object.body.string
        else
          say "s3://#{@bucket}/#{name}/#{@jenkins_config_file}"
          say "Last updated #{@object.last_modified.localtime.strftime("%d/%m/%Y %I:%M %p")}"
        end
      end
      
    end
  end
end