require 'thor'
require 'terminal-table'
require 'ciinabox/cluster'

module Ciinabox
  class Services < Thor::Group
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
