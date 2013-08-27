# Make prerequisites re-evaluated when changed
module Rake
  class Task

    # Data stored in the task itself, built during its invocation.
    # Useful to represent targets having data not stored in a file.
    attr_accessor :data

    # Keep original method
    alias :invoke_prerequisites_ORG :invoke_prerequisites
    # Rewrite it
    def invoke_prerequisites(task_args, invocation_chain)
      prerequisites_changed = true
      while (prerequisites_changed)
        # Keep original prerequisites list
        original_prerequisites = prerequisite_tasks.clone
        # Call original method (this call might change the prerequisites list)
        invoke_prerequisites_ORG(task_args, invocation_chain)
        prerequisites_changed = (prerequisite_tasks != original_prerequisites)
      end
    end

  end
end
