require 'thor'
require 'terminal-table'
require 'ciinabox/utils'

module Ciinabox
  class BucketPolicy < Thor::Group
    include Thor::Actions

    argument :name

    class_option :profile, desc: 'AWS Profile'
    class_option :region, default: ENV['AWS_REGION'], desc: 'AWS Region'
    
    class_option :update, type: :boolean, default: false, desc: 'updates the bucket policy'

    def self.source_root
      File.dirname(__FILE__)
    end

    def set_ciinabox_config
      @build_dir = '.build'
      @config_file = "#{@name}.ciinabox.yaml"
      @config = YAML.load(File.read(@config_file))
    end

    def update_policy
      if @options['update']
        say "Updating the bucket policy for #{@config['source_bucket']}"
        Ciinabox::Utils.set_bucket_policy(@config['source_bucket'],@name)
      end
    end

    def show_policy
      puts JSON.pretty_generate(Ciinabox::Utils.get_bucket_policy(@config['source_bucket']))
    end
        
  end
end
