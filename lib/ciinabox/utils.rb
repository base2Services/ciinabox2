require 'aws-sdk-core'
require 'aws-sdk-route53'
require 'resolv'

module Ciinabox
  class Utils
    class << self

      def aws_account_id()
        sts = Aws::STS::Client.new()
        resp = sts.get_caller_identity()
        return resp[:account]
      end

      def route53_hostedzone_exists?(zone)
        route53 = Aws::Route53::Client.new()
        resp = route53.list_hosted_zones_by_name({dns_name: zone})
        return resp.hosted_zones.select { |hz| hz.name.chomp('.') == zone }.any?
      end

      def dns_is_resolvable?(zone)
        return ((Resolv::DNS.new.getresources(zone, Resolv::DNS::Resource::IN::NS)).any?) ? true : false
      end

      def valid_dns_name?(zone)
        return (zone =~ /^([a-z0-9]+(-[a-z0-9]+)*\.)+[a-z]{2,}$/)
      end

    end
  end
end
