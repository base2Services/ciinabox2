require 'aws-sdk-cloudformation'

require 'ciinabox/version'
require 'ciinabox/log'

module Ciinabox
  class Cloudformation
    include Ciinabox::Log

    def initialize(name)
      @name = name
      @stack_name = "#{@name}-ciinabox"
      @client = Aws::CloudFormation::Client.new()
    end

    # TODO: check for REVIEW_IN_PROGRESS
    def does_cf_stack_exist()
      begin
        resp = @client.describe_stacks({
          stack_name: @stack_name,
        })
      rescue Aws::CloudFormation::Errors::ValidationError
        return false
      end
      return resp.size > 0
    end

    def get_change_set_type()
      return does_cf_stack_exist() ? 'UPDATE' : 'CREATE'
    end

    def create_change_set(template_url, parameters={})
      change_set_name = "#{@stack_name}-#{Ciinabox::CHANGE_SET_VERSION}-#{Time.now.utc.strftime("%Y%m%d%H%M%S")}"
      change_set_type = get_change_set_type()
      template_params = get_parameters_from_template(template_url)

      Log.logger.debug "Creating changeset"
      Log.logger.debug "Changeset parameters:\n #{template_params}"
      change_set = @client.create_change_set({
        stack_name: @stack_name,
        template_url: template_url,
        parameters: template_params,
        capabilities: ['CAPABILITY_IAM', 'CAPABILITY_NAMED_IAM', 'CAPABILITY_AUTO_EXPAND'],
        tags: [
          {
            key: "ciinabox:version",
            value: Ciinabox::VERSION,
          },
          {
            key: "ciinabox:name",
            value: @name,
          }
        ],
        change_set_name: change_set_name,
        change_set_type: change_set_type
      })
      return change_set, change_set_type
    end

    def wait_for_changeset(change_set_id)
      Log.logger.debug "Waiting for changeset to be created"
      begin
        @client.wait_until :change_set_create_complete, change_set_name: change_set_id
      rescue Aws::Waiters::Errors::FailureStateError => e
        change_set = get_change_set(change_set_id)
        Log.logger.error("change set status: #{change_set.status} reason: #{change_set.status_reason}")
        exit 1
      end
    end

    def get_change_set(change_set_id)
      @client.describe_change_set({
        change_set_name: change_set_id,
      })
    end

    def execute_change_set(change_set_id)
      Log.logger.debug "Executing the changeset"
      stack = @client.execute_change_set({
        change_set_name: change_set_id
      })
    end

    def wait_for_execute(change_set_type)
      waiter = change_set_type == 'CREATE' ? :stack_create_complete : :stack_update_complete
      Log.logger.debug "Waiting for changeset to #{change_set_type}"
      begin
        resp = @client.wait_until waiter, stack_name: @stack_name
        Log.logger.debug "Changeset #{change_set_type} complete"
      rescue Aws::Waiters::Errors::FailureStateError => e
        Log.logger.error "Changeset #{change_set_type} failed with error: #{e.message}"
      end
    end

    def get_parameters_from_stack()
      resp = @client.get_template_summary({ stack_name: @stack_name })
      return resp.parameters.collect { |p| { parameter_key: p.parameter_key, use_previous_value: true }  }
    end

    def get_parameters_from_template(template_url)
      resp = @client.get_template_summary({ template_url: template_url })
      return resp.parameters.collect { |p| { parameter_key: p.parameter_key, parameter_value: p.default_value }  }
    end
    
    def get_stack_errors()
      
    end

  end
end
