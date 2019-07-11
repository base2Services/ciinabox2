require 'thor'
require 'ciinabox/version'
require 'ciinabox/init'
require 'ciinabox/deploy'
require 'ciinabox/instances'
require 'ciinabox/services'
require 'ciinabox/agents'

module Ciinabox
  class Cli < Thor

    map %w[--version -v] => :__print_version
    desc "--version, -v", "print the version"
    def __print_version
      puts Ciinabox::VERSION
    end

    # Initializes ciinabox configuration
    register Ciinabox::Init, 'init', 'init [name]', 'Ciinabox configuration initialization'
    tasks["init"].options = Ciinabox::Init.class_options

    register Ciinabox::Deploy, 'deploy', 'deploy [name]', 'Ciinabox base stack creation'
    tasks["deploy"].options = Ciinabox::Deploy.class_options

    register Ciinabox::Instances, 'instances', 'instances [name]', 'describe the ciinabox ECS cluster instances'
    tasks["instances"].options = Ciinabox::Instances.class_options

    register Ciinabox::Services, 'services', 'services [name]', 'describe ciinabox deployed services'
    tasks["services"].options = Ciinabox::Services.class_options

    register Ciinabox::Agents, 'agents', 'agents [name]', 'describe ciinabox available ECS agents'
    tasks["agents"].options = Ciinabox::Agents.class_options

  end

  Aws.config[:retry_limit] = if ENV.key? 'CIINABOX_AWS_RETRY_LIMIT' then (ENV['CIINABOX_AWS_RETRY_LIMIT'].to_i) else 10 end

end
