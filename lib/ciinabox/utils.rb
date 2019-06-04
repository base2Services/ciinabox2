require 'aws-sdk-core'
require 'aws-sdk-route53'
require 'resolv'

module Ciinabox

  class Utils

    def self.aws_account_id()
      sts = Aws::STS::Client.new()
      resp = sts.get_caller_identity()
      return resp[:account]
    end

    def self.route53_hostedzone_exists?(zone)
      route53 = Aws::Route53::Client.new()
      resp = route53.list_hosted_zones_by_name({dns_name: zone})
      return resp.hosted_zones.select { |hz| hz.name.chomp('.') == zone }.any?
    end

    def self.dns_is_resolvable?(zone)
      return ((Resolv::DNS.new.getresources(zone, Resolv::DNS::Resource::IN::NS)).any?) ? true : false
    end

    def self.valid_dns_name?(zone)
      return (zone =~ /^([a-z0-9]+(-[a-z0-9]+)*\.)+[a-z]{2,}$/)
    end

    def self.does_cf_stack_exist(stack_name, region)
      cloudformation = Aws::CloudFormation::Client.new(region: region)
      resp = cloudformation.describe_stacks({
        stack_name: stack_name,
      })
      return resp.size > 0
    end

    def self.get_change_set_type(stack_name, region)
      return does_cf_stack_exist(stack_name, region) ? 'UPDATE' : 'CREATE'
    end

    def self.create_change_set(stack_name, template_url, region)
      cloudformation = Aws::CloudFormation::Client.new(region: region)
      change_set_name = "#{stack_name}-#{Ciinabox::CHANGE_SET_VERSION}"
      change_set_type = Utils.get_change_set_type(stack_name, Aws.config[:region])
      change_set = cloudformation.create_change_set({
        stack_name: stack_name,
        template_url: template_url,
        capabilities: ['CAPABILITY_IAM', 'CAPABILITY_NAMED_IAM', 'CAPABILITY_AUTO_EXPAND'],
        tags: [
          {
            key: "ciinabox-version",
            value: Ciinabox::VERSION,
          },
        ],
        change_set_name: change_set_name,
        change_set_type: change_set_type
      })
      resp = cloudformation.wait_until :change_set_create_complete, change_set_name: change_set.id
      return change_set, change_set_type
    end

    def self.apply_change_set(stack_name, change_set, change_set_type, region)
      cloudformation = Aws::CloudFormation::Client.new(region: region)
      Ciinabox.log.info("applying changes #{change_set.id}")
      change_details = cloudformation.describe_change_set({
        change_set_name: change_set.id
      })
      change_details.changes.each do |change|
        resource_change = change.resource_change
        Ciinabox.log.info("#{change.type} - #{resource_change.action} - #{resource_change.logical_resource_id} - #{resource_change.resource_type} - is replacement #{resource_change.replacement.nil? ? false : resource_change.replacement}")
        Ciinabox.log.debug("change details: #{resource_change.details}")
      end
      stack = cloudformation.execute_change_set({
        change_set_name: change_set.id
      })
      waiter = change_set_type == 'CREATE' ? :stack_create_complete : :stack_update_complete
      resp = cloudformation.wait_until waiter, stack_name: stack_name
      stack_version =  resp[:stacks][0][:outputs].find { |o| o[:output_key] == 'CfTemplateVersion' }[:output_value]
      return stack_version
    end

  end
end
