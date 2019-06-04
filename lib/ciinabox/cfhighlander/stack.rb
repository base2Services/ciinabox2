require 'cfhighlander.publisher'
require 'cfhighlander.factory'
require 'cfhighlander.validator'
require 'ciinabox/cfhighlander/utils'

module Ciinabox
  module CfHiglander
    class Stack
      def initialize(ciinabox_config, output_dir)
        @ciinabox_component = "#{ciinabox_config['ciinabox_name']}"
        @ciinabox_config = load_ciinabox_config(output_dir, @ciinabox_component, ciinabox_config)
        @cfn_output_format = 'yaml'
        @region = @ciinabox_config['aws_region']
        Aws.config[:region] = @region
        ENV['CFHIGHLANDER_WORKDIR'] = output_dir
        ENV['HIGHLANDER_WORKDIR'] = output_dir
        ENV['HL_VPC_AZ_LOCAL_ONLY'] = '1'
      end

      def deploy()
        cf_compiler = render_cfhighlander_component(@ciinabox_component)
        template_url = publish_cf_templates(cf_compiler)
        deploy_stack(template_url, @region)
      end

      private

      def deploy_stack(template_url, region)
        stack_name = "#{@ciinabox_component}-ciinabox"
        puts("creating changeset for #{stack_name} stack")
        change_set, change_set_type = Utils.create_change_set(stack_name, template_url, region)
        stack_version = Utils.apply_change_set(stack_name, change_set, change_set_type, region)
        puts("updated ciinabox to version #{stack_version}")
      end

      def publish_cf_templates(cf_compiler)
        publisher = Cfhighlander::Publisher::ComponentPublisher.new(cf_compiler.component, false, 'yaml')
        publisher.publishFiles(cf_compiler.cfn_template_paths + cf_compiler.lambda_src_paths)
        puts("ciinabox template url: #{publisher.getTemplateUrl}")
        return publisher.getTemplateUrl
      end

      def render_cfhighlander_component(component_name)

        factory = Cfhighlander::Factory::ComponentFactory.new
        component = factory.loadComponentFromTemplate(component_name)
        component.config = @ciinabox_config
        component.version = Ciinabox::VERSION
        component.load()
        component_compiler = Cfhighlander::Compiler::ComponentCompiler.new(component)
        component_compiler.compileCloudFormation(@cfn_output_format)
        component_validator = Cfhighlander::Cloudformation::Validator.new(component)
        component_validator.validate(component_compiler.cfn_template_paths, @cfn_output_format)

        return component_compiler
      end

      def load_ciinabox_config(config_dir, ciinabox_name, config)
        config_file = "#{config_dir}/#{ciinabox_name}.config.yaml"
        puts("Loading ciinabox config #{config_file}")
        ciinabox_config = YAML.load(File.read(config_file))
        if(not ciinabox_config)
          raise StandardError.new("Unable to load ciinabox config file #{config_file}")
        end
        ciinabox_config.merge!(config)
        return ciinabox_config
      end

    end
  end
end
