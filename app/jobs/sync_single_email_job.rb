class SyncSingleEmailJob < ApplicationJob
  queue_as :default

  def perform(user_id, message_id)
    user = User.find(user_id)
    email_processor = EmailProcessorService.new(user)
    email_processor.process_and_sync(message_id)
  end
end
