require 'aws-sdk-ecs'

module Ciinabox
  class Cluster

    def initialize(name)
      @client = Aws::ECS::Client.new()
      @name = name
      @cluster = "#{@name}-ciinabox"
    end

    def get_services()
      list = @client.list_services({
        cluster: @cluster
      })
      if list.service_arns.any?
        resp = @client.describe_services({
          cluster: @cluster,
          services: list.service_arns,
          include: ["TAGS"]
        })
        return resp.services
      else
        return []
      end
    end

    def get_agents()
      resp = @client.list_task_definitions({
        status: "ACTIVE"
      })

      tasks = []
      resp.task_definition_arns.each do |task|
        task_def = get_task_definition(task)
        if task_def.tags.detect { |t| t.key == "ciinabox:agent:label" }
          tasks << task_def
        end
      end

      return tasks
    end

    def get_instances()
      list = @client.list_container_instances({
        cluster: @cluster
      })
      if list.container_instance_arns.any?
        instances = @client.describe_container_instances({
          cluster: @cluster,
          container_instances: list.container_instance_arns,
          include: ["TAGS"],
        })
        return instances.container_instances
      else
        return []
      end
    end

    def get_task_definition(task)
      @client.describe_task_definition({
        task_definition: task,
        include: ["TAGS"]
      })
    end

  end
end
