# frozen_string_literal: true

# SendAssessmentsJob: sends assessment reminder to patients
class SendAssessmentsJob < ApplicationJob
  queue_as :default

  def perform(*_args)
    Patient.reminder_eligible.find_each(batch_size: 5000, &:send_assessment)
  end
end
