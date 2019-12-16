require 'aws-sdk-codebuild'
require 'time'
require 'ciinabox/log'

module Ciinabox
  class CodeBuild
    include Ciinabox::Log
    
    attr_reader :errors, :logs
    
    def initialize(project_name)
      @project_name = project_name
      @errors = []
      @logs = nil
      @client = Aws::CodeBuild::Client.new()
    end
    
    def trigger_build(source_version,wait=true)
      resp = @client.start_build({
        project_name: @project_name,
        source_version: source_version
      })
      Log.logger.info "Trigged build #{resp.build.id} from source #{source_version}"
      wait(resp.build.id) if wait
    end
    
    def wait(id)
      status = 'IN_PROGRESS'
      phase = 'SUBMITTED'
      while status == 'IN_PROGRESS'
        Log.logger.info "waiting for build to complete. STATUS: #{status}, PHASE: #{phase}"
        sleep(3)
        resp = @client.batch_get_builds({
          ids: [id]
        })
        build = resp.builds.first
        status = build.build_status
        phase = build.current_phase
      end
      Log.logger.info "Finished waiting for build with status #{status}"
      @logs = build.logs.deep_link
      @errors = build.phases.select {|p| p.phase_status == 'FAILED' }
      @errors.map! {|e| {phase: e.phase_type, message: e.contexts.map {|c| c.message}} } if @errors.any?
    end
    
  end
end