require 'aws-sdk-ec2'

module Ciinabox
  class Fleet 
  
    def initialize(name) 
      @name = name
      @client = Aws::EC2::Client.new()
    end
    
    def get_spot_fleets
      resp = @client.describe_spot_fleet_requests {|r| r.contents.map(&:key)}
      return resp.spot_fleet_request_configs.select { |sf| sf.spot_fleet_request_state == 'active' }
    end
    
    def get_launch_tempate_version(template_name)
      resp = @client.describe_launch_templates({
        launch_template_names: [template_name],
      })
      return resp.launch_templates[0].latest_version_number
    end
  
  end
end
