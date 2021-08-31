require 'cfhighlander.publisher'
require 'cfhighlander.factory'
require 'cfhighlander.validator'

require 'ciinabox/version'
require 'ciinabox/log'

module Ciinabox
  class CfHighlander
    include Ciinabox::Log

    INLINED_TEMPLATES = ["jenkinsTask"]

    def initialize(config, build_dir)
      @config = config
      @build_dir = build_dir
      @cfn_output_format = 'yaml'
      ENV['CFHIGHLANDER_WORKDIR'] = @build_dir
      ENV['HIGHLANDER_WORKDIR']  = @build_dir
    end

    def render()
      Log.logger.debug "loading cfhighlander components"
      component = load_component()
      Log.logger.debug "compiling cfhighlander templates into cloudformation"
      compiler = compile_component(component)
      Log.logger.debug "removing inlined templates"
      INLINED_TEMPLATES.each {|t| compiler.cfn_template_paths.delete("#{@build_dir}/out/yaml/#{t}.compiled.yaml")}
      Log.logger.debug "Validating compiled cloudformation templates"
      validate_component(component,compiler.cfn_template_paths)
      return compiler
    end

    def publish(cf_compiler)
      publisher = Cfhighlander::Publisher::ComponentPublisher.new(cf_compiler.component, false, @cfn_output_format)
      Log.logger.debug "publishing compiled templates to s3"
      publisher.publishFiles(cf_compiler.cfn_template_paths + cf_compiler.lambda_src_paths)
      Log.logger.debug "ciinabox template url: #{publisher.getTemplateUrl}"
      return publisher.getTemplateUrl
    end

    private

    def load_component()
      factory = Cfhighlander::Factory::ComponentFactory.new
      component = factory.loadComponentFromTemplate('ciinabox')
      component.config = load_config()
      component.version = Ciinabox::VERSION
      component.load()
      return component
    end

    def compile_component(component)
      component_compiler = Cfhighlander::Compiler::ComponentCompiler.new(component)
      component_compiler.silent_mode = true
      component_compiler.compileCloudFormation(@cfn_output_format)
      return component_compiler
    end

    def validate_component(component,template_paths)
      component_validator = Cfhighlander::Cloudformation::Validator.new(component)
      component_validator.validate(template_paths, @cfn_output_format)
    end

    def load_config()
      config_file = "#{@build_dir}/ciinabox.config.yaml"
      ciinabox_config = YAML.load(File.read(config_file))
      return ciinabox_config.deep_merge(@config)
    end

  end
end

class ::Hash
  def deep_merge(second)
    merger = proc {|key, v1, v2| Hash === v1 && Hash === v2 ? v1.merge(v2, &merger) : Array === v1 && Array === v2 ? v1 | v2 : [:undefined, nil, :nil].include?(v2) ? v1 : v2}
    self.merge(second.to_h, &merger)
  end
end