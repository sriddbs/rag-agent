class ToolSchemas
  ALL_TOOLS = [
    {
      type: 'function',
      function: {
        name: 'search_emails',
        description: 'Search through emails for specific information',
        parameters: {
          type: 'object',
          properties: {
            query: {
              type: 'string',
              description: 'The search query'
            }
          },
          required: ['query']
        }
      }
    },
    {
      type: 'function',
      function: {
        name: 'send_email',
        description: 'Send an email to a recipient',
        parameters: {
          type: 'object',
          properties: {
            to: {
              type: 'string',
              description: 'Email address of recipient'
            },
            subject: {
              type: 'string',
              description: 'Email subject'
            },
            body: {
              type: 'string',
              description: 'Email body content'
            }
          },
          required: ['to', 'subject', 'body']
        }
      }
    },
    {
      type: 'function',
      function: {
        name: 'search_calendar',
        description: 'Search calendar events',
        parameters: {
          type: 'object',
          properties: {
            query: {
              type: 'string',
              description: 'Search query or date range'
            },
            start_date: {
              type: 'string',
              description: 'Start date (ISO 8601 format)'
            },
            end_date: {
              type: 'string',
              description: 'End date (ISO 8601 format)'
            }
          }
        }
      }
    },
    {
      type: 'function',
      function: {
        name: 'create_calendar_event',
        description: 'Create a new calendar event',
        parameters: {
          type: 'object',
          properties: {
            summary: {
              type: 'string',
              description: 'Event title'
            },
            start_time: {
              type: 'string',
              description: 'Start time (ISO 8601 format)'
            },
            end_time: {
              type: 'string',
              description: 'End time (ISO 8601 format)'
            },
            attendees: {
              type: 'array',
              items: { type: 'string' },
              description: 'List of attendee emails'
            },
            description: {
              type: 'string',
              description: 'Event description'
            }
          },
          required: ['summary', 'start_time', 'end_time']
        }
      }
    },
    {
      type: 'function',
      function: {
        name: 'search_hubspot_contacts',
        description: 'Search for contacts in Hubspot CRM',
        parameters: {
          type: 'object',
          properties: {
            query: {
              type: 'string',
              description: 'Search query (name, email, etc.)'
            }
          },
          required: ['query']
        }
      }
    },
    {
      type: 'function',
      function: {
        name: 'create_hubspot_contact',
        description: 'Create a new contact in Hubspot',
        parameters: {
          type: 'object',
          properties: {
            email: {
              type: 'string',
              description: 'Contact email'
            },
            firstname: {
              type: 'string',
              description: 'First name'
            },
            lastname: {
              type: 'string',
              description: 'Last name'
            },
            phone: {
              type: 'string',
              description: 'Phone number'
            }
          },
          required: ['email']
        }
      }
    },
    {
      type: 'function',
      function: {
        name: 'update_hubspot_contact',
        description: 'Update an existing contact in Hubspot',
        parameters: {
          type: 'object',
          properties: {
            contact_id: {
              type: 'string',
              description: 'Hubspot contact ID to update'
            },
            email: {
              type: 'string',
              description: 'Contact email'
            },
            firstname: {
              type: 'string',
              description: 'First name'
            },
            lastname: {
              type: 'string',
              description: 'Last name'
            },
            phone: {
              type: 'string',
              description: 'Phone number'
            }
          },
          required: ['contact_id']
        }
      }
    },
    {
      type: 'function',
      function: {
        name: 'add_hubspot_note',
        description: 'Add a note to a Hubspot contact',
        parameters: {
          type: 'object',
          properties: {
            contact_id: {
              type: 'string',
              description: 'Hubspot contact ID'
            },
            note: {
              type: 'string',
              description: 'Note content'
            }
          },
          required: ['contact_id', 'note']
        }
      }
    },
    {
      type: 'function',
      function: {
        name: 'create_ongoing_instruction',
        description: 'Create a new ongoing instruction/rule that the agent should always remember and follow. Can be conditional (WHEN X THEN Y) or general.',
        parameters: {
          type: 'object',
          properties: {
            title: {
              type: 'string',
              description: 'Short title for the rule (optional, will be auto-generated)'
            },
            condition: {
              type: 'string',
              description: 'When should this rule apply? (e.g., "someone emails me who is not in Hubspot", "I create a contact in Hubspot")'
            },
            action: {
              type: 'string',
              description: 'What should happen? (e.g., "create a contact in Hubspot with a note", "send them a welcome email")'
            },
            priority: {
              type: 'string',
              enum: ['high', 'medium', 'low'],
              description: 'Priority level (default: medium)'
            },
            category: {
              type: 'string',
              enum: ['email', 'calendar', 'hubspot', 'general'],
              description: 'Category for organization'
            },
            instruction: {
              type: 'string',
              description: 'Alternative: provide a natural language instruction (e.g., "When someone emails me, create them in Hubspot") and it will be parsed'
            }
          }
        }
      }
    },
    {
      type: 'function',
      function: {
        name: 'get_available_calendar_slots',
        description: 'Get available time slots from calendar for scheduling',
        parameters: {
          type: 'object',
          properties: {
            start_date: {
              type: 'string',
              description: 'Start date to check availability (ISO 8601 format)'
            },
            end_date: {
              type: 'string',
              description: 'End date to check availability (ISO 8601 format)'
            },
            duration_minutes: {
              type: 'integer',
              description: 'Duration of meeting in minutes (default: 30)',
              default: 30
            }
          }
        }
      }
    }
  ].freeze
end
