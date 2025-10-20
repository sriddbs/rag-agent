module ToolExecutors
  class SendEmail
    def initialize(user)
      @user = user
    end

    def execute(args)
      gmail = @user.google_client.gmail_service

      message = create_message(
        to: args['to'],
        subject: args['subject'],
        body: args['body']
      )

      gmail.send_user_message('me', message)

      {
        success: true,
        message: "Email sent to #{args['to']}",
        data: { to: args['to'], subject: args['subject'] }
      }
    rescue => e
      { success: false, message: "Failed to send email: #{e.message}" }
    end

    private

    def create_message(to:, subject:, body:)
      mail = Mail.new(
        from: @user.email,
        to: to,
        subject: subject,
        body: body
      )

      Google::Apis::GmailV1::Message.new(
        raw: Base64.urlsafe_encode64(mail.to_s)
      )
    end
  end
end
