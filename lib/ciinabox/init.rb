require 'thor'
require 'ciinabox/utils'
require 'ciinabox/log'

module Ciinabox
  class Init < Thor::Group
    include Thor::Actions
    include Ciinabox::Log

    argument :name
    
    class_option :verbose, desc: 'set log level to debug', type: :boolean
    
    def self.source_root
      File.dirname(__FILE__)
    end

    def set_loglevel
      Log.logger.level = Logger::DEBUG if @options[:verbose]
    end

    def set_config
      @setup = {}
      @setup[:ciinabox_name] = name
      @setup[:version] = Ciinabox::VERSION
      @setup[:aws_account_id] = Utils.aws_account_id()
      Log.logger.debug "Using account-id #{@setup[:aws_account_id]}"
    end

    def set_directory
      @dir = ask "directory name ", default: "#{@name}-ciinabox"
      empty_directory @dir
    end
    
    def set_region
      region = ask "what region would you like to deploy ciinabox?", default: ENV['AWS_REGION']
      @setup[:region] = region
    end

    def set_source_bucket
      @setup[:source_bucket] = ask "ciinabox S3 bucket name ", default: "ciinabox.#{name}.#{@setup[:region]}.#{@setup[:aws_account_id]}"
    end
    
    def set_dns
      root_domain = ask "what hosted zone are you using?"
      @setup[:root_domain] = root_domain
    end

    def set_ip_whitelisting
      ip_whitelist = ask "what IP CIDRs are you whitelisting?"
      @setup[:ip_whitelist] = ip_whitelist.split(' ')
    end

    def create_ciinabox_config
      opts = {setup: @setup}
      template('templates/ciinabox.config.yaml.tt', "#{@dir}/ciinabox.yaml", opts)
    end
    
    def git_init
      if yes?("git init ciinabox?")
        run "git init #{@dir}"
        template 'templates/gitignore.tt', "#{@dir}/.gitignore"
        template "templates/README.md.tt", "#{@dir}/README.md"
      else
        say "Skipping git init", :yellow
      end
    end

    def complete
      say "ciinabox init complete. run `cd #{@dir}` and `ciinabox deploy #{@name}` to launch the stack", :green
    end

  end
end
