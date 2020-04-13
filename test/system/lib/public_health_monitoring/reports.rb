# frozen_string_literal: true

require 'application_system_test_case'

require_relative '../assessment/form'
require_relative 'history_verifier'
require_relative 'reports_verifier'
require_relative '../system_test_utils'

class PublicHealthMonitoringReports < ApplicationSystemTestCase
  @@assessment_form = AssessmentForm.new(nil)
  @@public_health_monitoring_history_verifier = PublicHealthMonitoringHistoryVerifier.new(nil)
  @@public_health_monitoring_reports_verifier = PublicHealthMonitoringReportsVerifier.new(nil)
  @@system_test_utils = SystemTestUtils.new(nil)

  def add_report(user_name, assessment)
    click_on '(add new)'
    @@assessment_form.submit_assessment(assessment['symptoms'])
    @@public_health_monitoring_reports_verifier.verify_add_report(user_name, assessment)
    search_for_report(user_name)
    @@public_health_monitoring_history_verifier.verify_add_report(user_name)
  end

  def edit_report(user_name, patient_key, assessment_id, assessment, submit=true)
    search_for_report(assessment_id)
    click_on 'Edit'
    @@assessment_form.submit_assessment(assessment['symptoms'])
    if submit
      page.driver.browser.switch_to.alert.accept
      search_for_report(assessment_id)
      @@public_health_monitoring_reports_verifier.verify_edit_report(user_name, assessment_id, assessment)
      @@public_health_monitoring_history_verifier.verify_edit_report(user_name)
    else
      page.driver.browser.switch_to.alert.dismiss
      assert page.has_content?('Daily Self-Report'), @@system_test_utils.get_err_msg('Edit report', 'title', 'existent')
      find('button', class: 'close').click
    end
  end

  def add_note_to_report(user_name, patient_key, assessment_id, note, submit=true)
    search_for_report(assessment_id)
    click_on 'Add Note'
    fill_in 'comment', with: note
    if submit
      click_on 'Submit'
      @@public_health_monitoring_history_verifier.verify_add_note_to_report(user_name, assessment_id, note)
    else
      click_on 'Cancel'
    end
  end

  def mark_all_as_reviewed(user_name, reasoning, submit=true)
    click_on 'Mark All As Reviewed'
    fill_in 'reasoning', with: reasoning
    if submit
      click_on 'Submit'
      @@public_health_monitoring_history_verifier.verify_mark_all_as_reviewed(user_name, reasoning)
    else
      click_on 'Cancel'
    end
    @@system_test_utils.wait_for_modal_animation
  end

  def pause_notifications(user_name, submit=true)
    pause_notifications = find('#pause_notifications').text == 'Resume Notifications'
    find('#pause_notifications').click
    if submit
      page.driver.browser.switch_to.alert.accept
      @@public_health_monitoring_reports_verifier.verify_pause_notifications(!pause_notifications)
      @@public_health_monitoring_history_verifier.verify_pause_notifications(user_name, !pause_notifications)
    else
      page.driver.browser.switch_to.alert.dismiss
      @@public_health_monitoring_reports_verifier.verify_pause_notifications(pause_notifications)
    end
  end

  def search_for_report(query)
    fill_in 'Search:', with: query
  end
end