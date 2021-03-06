# frozen_string_literal: true

# AssessmentsController: for assessment actions
class AssessmentsController < ApplicationController
  def index; end

  def new
    @assessment = Assessment.new
    @patient_submission_token = params[:patient_submission_token]

    # If monitoree, limit number of reports per time period
    if current_user.nil?
      if AssessmentReceipt.where(submission_token: @patient_submission_token)
                          .where('created_at >= ?', ADMIN_OPTIONS['reporting_limit'].minutes.ago).exists?
        redirect_to(already_reported_report_url) && return if ADMIN_OPTIONS['report_mode']

        redirect_to(already_reported_url) && return
      end
    end

    jurisdiction = Jurisdiction.find_by(unique_identifier: params[:unique_identifier]) if ADMIN_OPTIONS['report_mode']
    jurisdiction = Patient.find_by(submission_token: params[:patient_submission_token]).jurisdiction unless ADMIN_OPTIONS['report_mode']
    reporting_condition = jurisdiction.hierarchical_condition_unpopulated_symptoms
    @symptoms = reporting_condition.symptoms
    @threshold_hash = jurisdiction.hierarchical_symptomatic_condition.threshold_condition_hash
  end

  def create
    if ADMIN_OPTIONS['report_mode']
      # Limit number of reports per time period
      unless AssessmentReceipt.where(submission_token: @patient_submission_token)
                              .where('created_at >= ?', ADMIN_OPTIONS['reporting_limit'].minutes.ago).exists?
        assessment_placeholder = {}
        assessment_placeholder = assessment_placeholder.merge(params.permit(:response_status).to_h)
        assessment_placeholder = assessment_placeholder.merge(params.permit(:threshold_hash).to_h)
        assessment_placeholder = assessment_placeholder.merge(params.permit({ symptoms: %i[name value type label notes required] }).to_h)
        assessment_placeholder = assessment_placeholder.merge(params.permit(:patient_submission_token).to_h)
        # The generic 'experiencing_symptoms' boolean is used in cases where a user does not specify _which_ symptoms they are experiencing,
        # a value of true will result in an asesssment being marked as symptomatic regardless of if symptoms are specified
        unless params.permit(:experiencing_symptoms)['experiencing_symptoms'].blank?
          experiencing_symptoms = (%w[yes yeah].include? params.permit(:experiencing_symptoms)['experiencing_symptoms'].downcase.gsub(/\W/, ''))
          assessment_placeholder['experiencing_symptoms'] = experiencing_symptoms
        end
        ProduceAssessmentJob.perform_later assessment_placeholder
        assessment_receipt = AssessmentReceipt.new(submission_token: params.permit(:patient_submission_token)[:patient_submission_token])
        assessment_receipt.save
      end
    else
      check_patient_token

      # If not in report mode, make sure user is authenticated!
      redirect_to(root_url) && return unless current_user&.can_create_patient_assessments?

      # The patient providing this assessment is identified through the submission_token
      patient = Patient.find_by(submission_token: params.permit(:patient_submission_token)[:patient_submission_token])

      redirect_to(root_url) && return unless patient

      threshold_condition_hash = params.permit(:threshold_hash)[:threshold_hash]
      threshold_condition = ThresholdCondition.where(threshold_condition_hash: threshold_condition_hash).first

      redirect_to(root_url) && return unless threshold_condition

      reported_symptoms_array = params.permit({ symptoms: %i[name value type label notes required] }).to_h['symptoms']

      typed_reported_symptoms = Condition.build_symptoms(reported_symptoms_array)

      reported_condition = ReportedCondition.new(symptoms: typed_reported_symptoms, threshold_condition_hash: threshold_condition_hash)

      @assessment = Assessment.new(reported_condition: reported_condition)
      @assessment.symptomatic = @assessment.symptomatic?

      @assessment.patient = patient

      # Determine if a user created this assessment or a monitoree
      if current_user.nil?
        @assessment.who_reported = 'Monitoree'
        @assessment.save
        # Save a receipt
        assessment_receipt = AssessmentReceipt.new(submission_token: params.permit(:patient_submission_token)[:patient_submission_token])
        assessment_receipt.save
      else
        @assessment.who_reported = current_user.email
        @assessment.save
        # Save a receipt
        assessment_receipt = AssessmentReceipt.new(submission_token: params.permit(:patient_submission_token)[:patient_submission_token])
        assessment_receipt.save
        history = History.new
        history.created_by = current_user.email
        comment = 'User created a new report. ID: ' + @assessment.id.to_s
        history.comment = comment
        history.patient = patient
        history.history_type = 'Report Created'
        history.save
      end

      patient.refresh_symptom_onset(@assessment&.id)

      redirect_to(patient_assessments_url)
    end
  end

  def update
    check_patient_token

    redirect_to root_url unless current_user&.can_edit_patient_assessments?
    patient = Patient.find_by(submission_token: params.permit(:patient_submission_token)[:patient_submission_token])
    assessment = Assessment.find_by(id: params.permit(:id)[:id])
    reported_symptoms_array = params.permit({ symptoms: %i[name value type label notes required] }).to_h['symptoms']

    typed_reported_symptoms = Condition.build_symptoms(reported_symptoms_array)

    # Figure out the change
    delta = []
    typed_reported_symptoms.each do |symptom|
      new_val = symptom.bool_value
      old_val = assessment.reported_condition&.symptoms&.find_by(name: symptom.name)&.bool_value
      unless new_val.nil? || old_val.nil?
        delta << symptom.name + '=' + (new_val ? 'Yes' : 'No') if new_val != old_val
      end
    end

    assessment.reported_condition.symptoms = typed_reported_symptoms
    assessment.symptomatic = assessment.symptomatic?
    # Monitorees can't edit their own assessments, so the last person to touch this assessment was current_user
    assessment.who_reported = current_user.email

    # Attempt to save and continue; else if failed redirect to index
    return unless assessment.save

    patient.refresh_symptom_onset(assessment.id)

    history = History.new
    history.created_by = current_user.email
    comment = 'User updated an existing report (ID: ' + assessment.id.to_s + ').'
    comment += ' Symptom updates: ' + delta.join(', ') + '.' unless delta.empty?
    history.comment = comment
    history.patient = patient
    history.history_type = 'Report Updated'
    history.save
    redirect_to(patient_assessments_url) && return
  end

  # For report mode instances, this is the default landing
  def landing
    redirect_to(root_url) && return unless ADMIN_OPTIONS['report_mode']
  end

  # The monitoree already reported. Give them an update
  def already_reported; end

  protected

  def check_patient_token
    redirect_to(root_url) && return if params.nil? || params[:patient_submission_token].nil?

    patient = Patient.find_by(submission_token: params.permit(:patient_submission_token)[:patient_submission_token])
    redirect_to(root_url) && return if patient.nil?
  end
end
