require 'thor'
require 'ciinabox/utils'

module Ciinabox
  class Init < Thor::Group
    include Thor::Actions

    argument :name, default: 'ciinabox'

    class_option :profile, desc: 'AWS Profile'
    class_option :region, default: ENV['AWS_REGION'], desc: 'AWS Region'

    def self.source_root
      File.dirname(__FILE__)
    end

    def set_config
      Aws.config[:profile] = options[:profile] if options.key?(:profile)
      Aws.config[:region] = options[:region]
      @setup = {}
      @setup[:ciinabox_name] = name
      @setup[:version] = Ciinabox::VERSION
      @setup[:aws_account_id] = Utils.aws_account_id()
      @setup[:aws_region] = options[:region]
      @errors = []
    end

    def set_directory
      @dir = ask "directory name ", default: "#{name}"
      empty_directory @dir
    end

    def set_ciiabox_source_bucket
      @setup[:ciinabox_source_bucket]= ask "ciinabox S3 bucket name ", default: "#{@setup[:aws_account_id]}.#{@setup[:aws_region]}.ciinabox"
    end

    def set_dns
      ask "what hosted zone are you using?"
    end

    def init_ciinabox
      opts = {setup: @setup}
      template('templates/ciinabox.config.yaml.tt', "#{@dir}/#{name}.ciinabox.yaml", opts)
    end

    def complete
      say "ciinabox init complete. run `cd #{@dir}` and `ciinabox create #{name}` to launch the stack", :green
    end

  end
end
