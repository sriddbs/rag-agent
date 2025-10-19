module ToolExecutors
  class CreateOngoingInstruction
    def initialize(user)
      @user = user
    end

    def execute(args)
      instruction = @user.ongoing_instructions.create!(
        instruction: args['instruction']
      )

      {
        success: true,
        message: "Ongoing instruction saved: #{args['instruction']}",
        data: { instruction_id: instruction.id }
      }
    end
  end
end
