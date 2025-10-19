module ToolExecutors
  class CreateOngoingInstruction
    def initialize(user)
      @user = user
    end

    def execute(args)
      # AI can provide structured or unstructured instruction
      if args['condition'] && args['action']
        # Structured format
        instruction = @user.ongoing_instructions.create!(
          title: args['title'] || generate_title(args['condition'], args['action']),
          condition: args['condition'],
          action: args['action'],
          meta: {
            priority: args['priority'] || 'medium',
            category: args['category'] || 'general',
            created_by: 'ai'
          }
        )
      else
        # Parse natural language instruction
        parsed = parse_instruction(args['instruction'])
        instruction = @user.ongoing_instructions.create!(
          title: parsed[:title],
          condition: parsed[:condition],
          action: parsed[:action],
          meta: {
            priority: 'medium',
            category: 'general',
            created_by: 'ai',
            original_text: args['instruction']
          }
        )
      end

      {
        success: true,
        message: "Ongoing instruction saved: #{instruction.title}",
        data: {
          instruction_id: instruction.id,
          title: instruction.title,
          condition: instruction.condition,
          action: instruction.action
        }
      }
    rescue => e
      { success: false, message: "Failed to create instruction: #{e.message}" }
    end

    private

    def generate_title(condition, action)
      # Simple title generation
      "#{condition[0..40]}... → #{action[0..30]}..."
    end

    def parse_instruction(text)
      # Simple parsing - could use AI to parse better
      # Expected format: "When X happens, do Y"

      if text =~ /when\s+(.+?),?\s+(?:then\s+)?(.+)/i
        {
          title: "Auto: #{text[0..50]}",
          condition: $1.strip,
          action: $2.strip
        }
      else
        {
          title: "General Rule",
          condition: "Always",
          action: text
        }
      end
    end
  end
end
