require 'thor'
require 'terminal-table'
require 'ciinabox/cluster'

module Ciinabox
  class Agents < Thor::Group
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
      headings = ['Name', 'Version', 'Task Definition', 'Type', 'CPU', 'Memory']
      rows = []
    
      cluster = Ciinabox::Cluster.new(@name)
      agents = cluster.get_agents()
      agents.each do |t|
        rows.push([
          t.tags.detect { |t| t.key == "ciinabox:agent:label" }.value,
          t.task_definition.revision,
          t.task_definition.family,
          t.task_definition.compatibilities.first,
          t.task_definition.cpu,
          t.task_definition.memory
        ])
      end
    
      puts Terminal::Table.new(:headings => headings,:rows => rows)
    end

  end
end
