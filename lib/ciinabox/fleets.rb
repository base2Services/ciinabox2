require 'thor'
require 'terminal-table'
require 'ciinabox/fleet'

module Ciinabox
  class Fleets < Thor::Group
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
    
    def fleets
      @rows = []
      @fleet = Ciinabox::Fleet.new(@new)      
      @fleet.get_spot_fleets.each do |t|
        ltc = t.spot_fleet_request_config.launch_template_configs[0].launch_template_specification
        ltv = @fleet.get_launch_tempate_version(ltc.launch_template_name)
        @rows.push([
          t.spot_fleet_request_id,
          t.spot_fleet_request_config.target_capacity,
          ltc.launch_template_name,
          ltc.version,
          ltv
        ])
      end
    end
    
    def display
      headings = ['Id', 'Capacity', 'Launch Template', 'Fleet Template Version', 'Latest Template Version']
      puts Terminal::Table.new(:headings => headings, :rows => @rows)
    end

  end
end
