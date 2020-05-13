# frozen_string_literal: true

# ApiController: API for interacting with Sara Alert
class Fhir::R4::ApiController < ActionController::API
  include ActionController::MimeResponds
  before_action :doorkeeper_authorize!, except: [:capability_statement]
  before_action :cors_headers

  # Return a resource given a type and an id.
  #
  # Supports (reading): Patient, Observation, QuestionnaireResponse
  #
  # GET /[:resource_type]/[:id]
  def show
    resource_type = params.permit(:resource_type)[:resource_type]&.downcase
    case resource_type
    when 'patient'
      resource = get_patient(params.permit(:id)[:id])
    when 'observation'
      resource = get_laboratory(params.permit(:id)[:id])
    when 'questionnaireresponse'
      resource = get_assessment(params.permit(:id)[:id])
    else
      status_bad_request && return
    end

    status_forbidden && return if resource.nil?

    status_ok(resource.as_fhir)
  end

  # Update a resource given a type and an id.
  #
  # Supports (updating): Patient
  #
  # PUT /fhir/r4/[:resource_type]/[:id]
  def update
    # Parse in the FHIR::Patient
    contents = FHIR.from_contents(request.body.string)
    status_bad_request && return if contents.nil? || !contents.valid?

    resource_type = params.permit(:resource_type)[:resource_type]&.downcase
    case resource_type
    when 'patient'
      updates = Patient.from_fhir(contents)
      resource = get_patient(params.permit(:id)[:id])
    else
      status_bad_request && return
    end

    status_forbidden && return if resource.nil?

    # Try to update the resource
    if updates.nil? || !resource.update(updates)
      status_bad_request
    else
      status_ok(resource.as_fhir)
    end
  end

  # Create a resource given a type.
  #
  # Supports (writing): Patient
  #
  # POST /fhir/r4/[:resource_type]
  def create
    # Parse in the FHIR::Patient
    contents = FHIR.from_contents(request.body.string)
    status_bad_request && return if contents.nil? || !contents.valid?

    resource_type = params.permit(:resource_type)[:resource_type]&.downcase
    case resource_type
    when 'patient'
      # Construct a Sara Alert Patient
      resource = Patient.new(Patient.from_fhir(contents))

      # Responder is self
      resource.responder = resource

      # Creator is authenticated user
      resource.creator = current_resource_owner

      # Jurisdiction is the authenticated user's jurisdiction
      resource.jurisdiction = current_resource_owner.jurisdiction

      # Generate a submission token for the new monitoree
      resource.submission_token = SecureRandom.hex(20) # 160 bits
    end

    status_bad_request && return if resource.nil?

    status_bad_request && return unless resource.save

    if resource_type == 'patient'
      # Send enrollment notification
      resource.send_enrollment_notification

      # Create a history for the enrollment
      history = History.new
      history.created_by = current_resource_owner.email
      history.comment = 'User enrolled monitoree.'
      history.patient = resource
      history.history_type = 'Enrollment'
      history.save
    end
    status_created(resource.as_fhir)
  end

  # Return a FHIR Bundle containing results that match the given query.
  #
  # Supports (searching): Patient
  #
  # GET /fhir/r4/[:resource_type]?parameter(s)
  def search
    resource_type = params.permit(:resource_type)[:resource_type]&.downcase
    case resource_type
    when 'patient'
      resources = search_patients(params.slice('family', 'given', 'telecom', 'email'))
    else
      status_bad_request && return
    end

    # Construct bundle from search query
    bundle = FHIR::Bundle.new(
      id: SecureRandom.uuid,
      meta: FHIR::Meta.new(lastUpdated: DateTime.now.strftime('%FT%T%:z')),
      type: 'searchset',
      total: resources.size,
      entry: resources.collect { |r| FHIR::Bundle::Entry.new(fullUrl: full_url_helper(request, r), resource: r) }
    )

    status_ok(bundle)
  end

  # Return a FHIR Bundle containing a monitoree and all their assessments and
  # lab results.
  #
  # GET /fhir/r4/Patient/[:id]/$everything
  def all
    patient = get_patient(params.permit(:id)[:id])

    status_forbidden && return if patient.nil?

    # Gather assessments and lab results
    assessments = patient.assessments || []
    laboratories = patient.laboratories || []
    all = [patient] + assessments.to_a + laboratories.to_a

    # Construct bundle from monitoree and data
    bundle = FHIR::Bundle.new(
      id: SecureRandom.uuid,
      meta: FHIR::Meta.new(lastUpdated: DateTime.now.strftime('%FT%T%:z')),
      type: 'searchset',
      total: all.size,
      entry: all.collect { |r| FHIR::Bundle::Entry.new(fullUrl: full_url_helper(request, r), resource: r.as_fhir) }
    )

    status_ok(bundle)
  end

  # Return a FHIR::CapabilityStatement
  #
  # GET /fhir/r4/CapabilityStatement
  def capability_statement
    resource = FHIR::CapabilityStatement.new(
      status: 'active',
      kind: 'instance',
      software: FHIR::CapabilityStatement::Software.new(
        name: 'Sara Alert',
        version: ADMIN_OPTIONS['version']
      ),
      implementation: FHIR::CapabilityStatement::Implementation.new(
        description: 'Sara Alert API'
      ),
      fhirVersion: '4.0.1',
      format: %w[xml json],
      rest: FHIR::CapabilityStatement::Rest.new(
        mode: 'server',
        security: FHIR::CapabilityStatement::Rest::Security.new(
          cors: true,
          service: FHIR::CodeableConcept.new(
            coding: [
              FHIR::Coding.new(code: 'OAuth', system: 'http://terminology.hl7.org/CodeSystem/restful-security-service')
            ]
          )
        ),
        resource: [
          FHIR::CapabilityStatement::Rest::Resource.new(
            type: 'Patient',
            interaction: [
              FHIR::CapabilityStatement::Rest::Resource::Interaction.new(code: 'read'),
              FHIR::CapabilityStatement::Rest::Resource::Interaction.new(code: 'update'),
              FHIR::CapabilityStatement::Rest::Resource::Interaction.new(code: 'create'),
              FHIR::CapabilityStatement::Rest::Resource::Interaction.new(code: 'search-type')
            ],
            searchParam: [
              FHIR::CapabilityStatement::Rest::Resource::SearchParam.new(name: 'family', type: 'string'),
              FHIR::CapabilityStatement::Rest::Resource::SearchParam.new(name: 'given', type: 'string'),
              FHIR::CapabilityStatement::Rest::Resource::SearchParam.new(name: 'telecom', type: 'string'),
              FHIR::CapabilityStatement::Rest::Resource::SearchParam.new(name: 'email', type: 'string')
            ]
          ),
          FHIR::CapabilityStatement::Rest::Resource.new(
            type: 'Observation',
            interaction: [
              FHIR::CapabilityStatement::Rest::Resource::Interaction.new(code: 'read')
            ]
          ),
          FHIR::CapabilityStatement::Rest::Resource.new(
            type: 'QuestionnaireResponse',
            interaction: [
              FHIR::CapabilityStatement::Rest::Resource::Interaction.new(code: 'read')
            ]
          )
        ]
      )
    )
    status_ok(resource)
  end

  # Handle OPTIONS requests for CORS preflight
  def options
    render plain: ''
  end

  private

  # Current user account as authenticated via doorkeeper
  def current_resource_owner
    User.find(doorkeeper_token.resource_owner_id) if doorkeeper_token
  end

  # Generic 400 bad request response
  def status_bad_request
    respond_to do |format|
      format.any { render json: { error: 'Bad request' }, status: :bad_request }
    end
  end

  # Generic 403 forbidden response
  def status_forbidden
    respond_to do |format|
      format.any { render json: { error: 'Forbidden' }, status: :forbidden }
    end
  end

  # Generic 201 created response
  def status_created(resource)
    respond_to do |format|
      format.json { render json: resource.to_json, status: :created }
      format.xml  { render xml: resource.to_xml, status: :created }
    end
  end

  # Generic 200 okay response
  def status_ok(resource)
    respond_to do |format|
      format.json { render json: resource.to_json, status: :ok }
      format.xml  { render xml: resource.to_xml, status: :ok }
    end
  end

  # Get a patient by id
  def get_patient(id)
    current_resource_owner.viewable_patients.find_by(id: id)
  end

  # Search for patients
  def search_patients(options)
    query = current_resource_owner.viewable_patients
    options.each do |option, search|
      case option
      when 'family'
        query = query.where('last_name like ?', "#{search}%")
      when 'given'
        query = query.where('first_name like ?', "#{search}%")
      when 'telecom'
        query = query.where('primary_telephone like ?', "#{search}%")
      when 'email'
        query = query.where('email like ?', "#{search}%")
      end
    end
    query.collect(&:as_fhir)
  end

  # Get a lab result by id
  def get_laboratory(id)
    Laboratory.where(patient_id: current_resource_owner.viewable_patients).find_by(id: id)
  end

  # Get an assessment by id
  def get_assessment(id)
    Assessment.where(patient_id: current_resource_owner.viewable_patients).find_by(id: id)
  end

  # Construct a full url via a request and resource
  def full_url_helper(_request, resource)
    "#{root_url}fhir/r4/#{resource.class.name.split('::').last}/#{resource.id}"
  end

  # Allow cross-origin requests
  def cors_headers
    headers['Access-Control-Allow-Origin'] = '*'
    headers['Access-Control-Allow-Headers'] = '*'
    headers['Access-Control-Allow-Methods'] = 'GET, POST, PUT, DELETE, OPTIONS'
  end
end
