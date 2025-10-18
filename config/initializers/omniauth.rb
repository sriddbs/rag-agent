Rails.application.config.middleware.use OmniAuth::Builder do
  provider :google_oauth2,
           "756826802737-as4sit73u6dv2qh37kdcameohat59ebt.apps.googleusercontent.com",
           "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",
           {
             scope: "email,profile,https://www.googleapis.com/auth/gmail.modify,https://www.googleapis.com/auth/calendar",
             prompt: "consent",
             access_type: "offline"
           }
end

OmniAuth.config.allowed_request_methods = %i[get post]
OmniAuth.config.silence_get_warning = true

