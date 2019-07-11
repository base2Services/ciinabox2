require 'thor'
require 'terminal-table'

require 'ciinabox/utils'

module Ciinabox
  class Instances < Thor::Group
    include Thor::Actions

    argument :name

    class_option :profile, desc: 'AWS Profile'
    class_option :region, default: ENV['AWS_REGION'], desc: 'AWS Region'

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
