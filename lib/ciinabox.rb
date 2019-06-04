require 'thor'
require 'ciinabox/version'
require 'ciinabox/init'
require 'ciinabox/deploy'

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

  end

  Aws.config[:retry_limit] = if ENV.key? 'CIINABOX_AWS_RETRY_LIMIT' then (ENV['CIINABOX_AWS_RETRY_LIMIT'].to_i) else 10 end

end
