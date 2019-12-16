require 'thor'
require 'terminal-table'

require 'ciinabox/utils'

module Ciinabox
  class Instances < Thor::Group
    include Thor::Actions

    argument :name
    
    class_option :verbose, desc: 'set log level to debug', type: :boolean
    class_option :region, desc: 'AWS region'

    def set_aws_config
      Aws.config[:region] = options[:region] if options.has_key?('region')
    end
    
    def self.source_root
      File.dirname(__FILE__)
    end

    def display
      headings = ['Instance Id', 'Status', 'Connected', 'Tasks', 'Agent', 'Docker', 'Type', 'Up Since']
      rows = []

      cluster = Ciinabox::Cluster.new(@name)
      instances = cluster.get_instances()
      instances.each do |i|
        rows.push([
          i.ec2_instance_id,
          i.status,
          i.agent_connected,
          i.running_tasks_count,
          i.version_info.agent_version,
          i.version_info.docker_version.gsub('DockerVersion: ',''),
          i.attributes.detect { |a| a.name == 'ecs.instance-type' }.value,
          i.registered_at
        ])
      end

      puts Terminal::Table.new(headings: headings, rows: rows)
    end

  end
end
