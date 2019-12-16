require 'thor'
require 'ciinabox/version'
require 'ciinabox/init'
require 'ciinabox/compile'
require 'ciinabox/deploy'
require 'ciinabox/instances'
require 'ciinabox/services'
require 'ciinabox/agents'
require 'ciinabox/fleets'
require 'ciinabox/jcasc/show_commits'
require 'ciinabox/jcasc/deploy'
require 'ciinabox/jcasc/s3_file'

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

    register Ciinabox::Compile, 'compile', 'compile [name]', 'Compile ciinabox configuration and cloudformation'
    tasks["compile"].options = Ciinabox::Compile.class_options

    register Ciinabox::Deploy, 'deploy', 'deploy [name]', 'Ciinabox base stack creation'
    tasks["deploy"].options = Ciinabox::Deploy.class_options

    register Ciinabox::Instances, 'instances', 'instances [name]', 'describe the ciinabox ECS cluster instances'
    tasks["instances"].options = Ciinabox::Instances.class_options

    register Ciinabox::Services, 'services', 'services [name]', 'describe ciinabox deployed services'
    tasks["services"].options = Ciinabox::Services.class_options

    register Ciinabox::Agents, 'agents', 'agents [name]', 'describe ciinabox available ECS agents'
    tasks["agents"].options = Ciinabox::Agents.class_options
    
    register Ciinabox::Fleets, 'fleets', 'fleets [name]', 'describe ciinabox spot fleet requests'
    tasks["fleets"].options = Ciinabox::Fleets.class_options

    register Ciinabox::Jcasc::ShowCommits, 'jcasc_show_commits', 'jcasc-show-commits [name]', 'display jenkins configuration as code commit hostory'
    tasks["jcasc_show_commits"].options = Ciinabox::Jcasc::ShowCommits.class_options

    register Ciinabox::Jcasc::Deploy, 'jcasc_deploy', 'jcasc-deploy [name]', 'deploy jenkins configuration as code from commit or branch'
    tasks["jcasc_deploy"].options = Ciinabox::Jcasc::Deploy.class_options
    
    register Ciinabox::Jcasc::S3File, 'jcasc_s3_file', 'jcasc-s3-file [name]', 'show jenkins configuration as code in s3'
    tasks["jcasc_s3_file"].options = Ciinabox::Jcasc::S3File.class_options
        
  end

  Aws.config[:retry_limit] = if ENV.key? 'CIINABOX_AWS_RETRY_LIMIT' then (ENV['CIINABOX_AWS_RETRY_LIMIT'].to_i) else 10 end

end
