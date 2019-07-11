require 'thor'
require 'ciinabox/utils'
require 'ciinabox/log'

module Ciinabox
  class Init < Thor::Group
    include Thor::Actions
    include Ciinabox::Log

    argument :name

    class_option :profile, desc: 'AWS Profile'
    class_option :region, default: ENV['AWS_REGION'], desc: 'AWS Region'
    class_option :verbose, desc: 'set log level to debug', type: :boolean

    def self.source_root
      File.dirname(__FILE__)
    end

    def set_loglevel
      Log.logger.level = Logger::DEBUG if @options[:verbose]
    end

    def set_config
      Aws.config[:profile] = options[:profile] if options.key?(:profile)
      Aws.config[:region] = options[:region]
      @setup = {}
      @setup[:ciinabox_name] = name
      @setup[:version] = Ciinabox::VERSION
      @setup[:aws_account_id] = Utils.aws_account_id()
      @setup[:aws_region] = options[:region]
      Log.logger.debug "Using account-id #{@setup[:aws_account_id]} in region #{@setup[:aws_region]}"
    end

    def set_directory
      @dir = ask "directory name ", default: "#{@name}-ciinabox"
      empty_directory @dir
    end

    def set_ciiabox_source_bucket
      @setup[:ciinabox_source_bucket]= ask "ciinabox S3 bucket name ", default: "#{@setup[:aws_account_id]}.#{@setup[:aws_region]}.ciinabox"
    end

    def set_dns
      root_domain = ask "what hosted zone are you using?"
      @setup[:root_domain] = root_domain
    end

    def set_ip_whitelisting
      ip_whitelist = ask "what IP CIDRs are you whitelisting?\nSpecify multiple IPs seperated by a space..."
      @setup[:ip_whitelist] = ip_whitelist.split(' ')
    end

    def create_ciinabox_config
      opts = {setup: @setup}
      template('templates/ciinabox.config.yaml.tt', "#{@dir}/#{@name}.ciinabox.yaml", opts)
    end

    def complete
      say "ciinabox init complete. run `cd #{@dir}` and `ciinabox deploy #{@name}` to launch the stack", :green
    end

  end
end
