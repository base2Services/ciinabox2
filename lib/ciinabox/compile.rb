require 'thor'
require 'yaml'

require 'ciinabox/cfhighlander'
require 'ciinabox/log'
require 'ciinabox/version'

module Ciinabox
  class Compile < Thor::Group
    include Thor::Actions
    include Ciinabox::Log

    argument :name
    
    class_option :verbose, desc: 'set log level to debug', type: :boolean
    class_option :region, desc: 'AWS region'
    
    class_option :publish, desc: 'publish templates to s3', default: false, type: :boolean
    class_option :template_config, desc: 'generate CodePipeline template config json file', default: false, type: :boolean

    def set_aws_config
      Aws.config[:region] = options[:region] if options.has_key?('region')
    end
    
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

    def generate_templates
      remove_dir @build_dir
      empty_directory @build_dir
      template('templates/ciinabox.cfhighlander.rb.tt', "#{@build_dir}/#{@name}.cfhighlander.rb", @config)
      template('templates/default.config.yaml.tt', "#{@build_dir}/#{@name}.config.yaml", @config)

      Log.logger.debug "Generating cloudformation from #{@build_dir}/#{@name}.cfhighlander.rb"
      cfhl = Ciinabox::CfHighlander.new(@name,@config,@build_dir)
      compiler = cfhl.render()
      if @options[:publish]
        Log.logger.debug "Publishing cloudformation templates to s3"
        template_url = cfhl.publish(compiler)
        say "Published templates to s3\n#{template_url}", :green
      end
    end

    def generate_pipeline_template_config
      if @options['template_config']
        template_config = {
          Tags: {
            'ciinabox:name': @name,
            'ciinabox:version': Ciinabox::VERSION
          },
          Parameters: {
            CiinaboxAmi: @config['ciinabox_ami']
          }
        }
        
        @config['agents'].each do |agent|
          template_config[:Parameters]["#{agent['name']}Ami"] = agent['ami']
        end if @config['agents'].any?
        
        File.write("template-config.ciinabox.json",template_config.to_json)
        say "Generated codepipeline json config file", :green
      end
    end

  end
end
