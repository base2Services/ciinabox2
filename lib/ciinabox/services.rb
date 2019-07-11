require 'thor'
require 'terminal-table'
require 'ciinabox/cluster'

module Ciinabox
  class Services < Thor::Group
    include Thor::Actions

    argument :name

    class_option :profile, desc: 'AWS Profile'
    class_option :region, default: ENV['AWS_REGION'], desc: 'AWS Region'

    def self.source_root
      File.dirname(__FILE__)
    end

    def display
      headings = ['Name', 'Status', 'Type', 'Running', 'CPU', 'Memory']
      rows = []

      cluster = Ciinabox::Cluster.new(@name)
      services = cluster.get_services()
      services.each do |s|
        task = cluster.get_task_definition(s.task_definition)
        rows.push([
          s.tags.detect { |t| t.key == "Name" }.value,
          s.status,
          s.launch_type,
          s.running_count,
          task.task_definition.cpu,
          task.task_definition.memory
        ])
      end

      puts Terminal::Table.new(:headings => headings,:rows => rows)
    end

  end
end
