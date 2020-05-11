require 'test_helper'

class ApiControllerTest < ActionDispatch::IntegrationTest
  fixtures :all

  setup do
    @user = User.find_by(email: 'state1_epi@example.com')
    @token = Doorkeeper::AccessToken.create(resource_owner_id: @user.id)
    @patient1 = Patient.find_by(id: 1).as_fhir
    @patient2 = Patient.find_by(id: 2).as_fhir
  end

  test 'should be unauthorized via show' do
    get '/fhir/r4/Patient/1'
    assert_response :unauthorized
  end

  test 'should get patient via show' do
    get '/fhir/r4/Patient/1', headers: { 'Authorization': "Bearer #{@token.token}" }
    assert_response :ok
    json_response = JSON.parse(response.body)
    assert_equal 1, json_response['id']
    assert_equal 'Patient', json_response['resourceType']
    assert_equal '1995-05-13', json_response['birthDate']
    assert_equal 3, json_response['telecom'].count
    assert_equal 'Boehm62', json_response['name'].first['family']
  end

  test 'should get observation via show' do
    get '/fhir/r4/Observation/1001', headers: { 'Authorization': "Bearer #{@token.token}" }
    assert_response :ok
    json_response = JSON.parse(response.body)
    assert_equal 1001, json_response['id']
    assert_equal 'Observation', json_response['resourceType']
    assert_equal 'Patient/1', json_response['subject']['reference']
    assert_equal 'positive', json_response['valueString']
  end

  test 'should get QuestionnaireResponse via show' do
    get '/fhir/r4/QuestionnaireResponse/1001', headers: { 'Authorization': "Bearer #{@token.token}" }
    assert_response :ok
    json_response = JSON.parse(response.body)
    assert_equal 1001, json_response['id']
    assert_equal 'QuestionnaireResponse', json_response['resourceType']
    assert_equal 'Patient/1', json_response['subject']['reference']
    assert_not json_response['item'].find(text: 'fever').first['answer'].first['valueBoolean']
    assert_not json_response['item'].find(text: 'cough').first['answer'].first['valueBoolean']
    assert_not json_response['item'].find(text: 'difficulty-breathing').first['answer'].first['valueBoolean']
  end

  test 'should be bad request via show' do
    get '/fhir/r4/FooBar/1', headers: { 'Authorization': "Bearer #{@token.token}" }
    assert_response :bad_request
  end

  test 'should be forbidden via show' do
    get '/fhir/r4/Patient/9', headers: { 'Authorization': "Bearer #{@token.token}" }
    assert_response :forbidden
  end


  test 'should be unauthorized via create' do
    post '/fhir/r4/Patient'
    assert_response :unauthorized
  end

  test 'should create Patient via create' do
    post '/fhir/r4/Patient', params: @patient1.to_json, headers: { 'Authorization': "Bearer #{@token.token}" }
    assert_response :created
    json_response = JSON.parse(response.body)
    id = json_response['id']
    p = Patient.find_by(id: id)
    assert_not p.nil?
    h = History.where(patient_id: id)
    assert_not h.first.nil?
    assert_equal 1, h.count
    assert_equal 'Patient', json_response['resourceType']
    assert_equal '1995-05-13', json_response['birthDate']
    assert_equal 3, json_response['telecom'].count
    assert_equal 'Boehm62', json_response['name'].first['family']
  end

  test 'should be bad request via create' do
    post '/fhir/r4/Patient', params: { foo: 'bar' }.to_json, headers: { 'Authorization': "Bearer #{@token.token}" }
    assert_response :bad_request
  end

  test 'should be unauthorized via update' do
    get '/fhir/r4/Patient/1'
    assert_response :unauthorized
  end

  test 'should update Patient via update' do
    put '/fhir/r4/Patient/1', params: @patient2.to_json, headers: { 'Authorization': "Bearer #{@token.token}" }
    assert_response :ok
    json_response = JSON.parse(response.body)
    assert_equal 1, json_response['id']
    p = Patient.find_by(id: 1)
    assert_not p.nil?
    assert_equal 'Patient', json_response['resourceType']
    assert_equal '1991-05-13', json_response['birthDate']
    assert_equal 'Kirlin44', json_response['name'].first['family']
  end

  test 'should be bad request via update' do
    put '/fhir/r4/Patient/1', params: { foo: 'bar' }.to_json, headers: { 'Authorization': "Bearer #{@token.token}" }
    assert_response :bad_request
  end

  test 'should be forbidden via update' do
    put '/fhir/r4/Patient/9', params: @patient2.to_json, headers: { 'Authorization': "Bearer #{@token.token}" }
    assert_response :forbidden
  end


  test 'should be unauthorized via search' do
    get '/fhir/r4/Patient?family=Kirlin44'
    assert_response :unauthorized
  end

  test 'should find Patient via search on existing family' do
    get '/fhir/r4/Patient?family=Kirlin44', headers: { 'Authorization': "Bearer #{@token.token}" }
    assert_response :ok
    json_response = JSON.parse(response.body)
    assert_equal 'Bundle', json_response['resourceType']
    assert_equal 1, json_response['total']
    assert_equal 2, json_response['entry'].first['resource']['id']
  end

  test 'should find no Patients via search on non-existing family' do
    get '/fhir/r4/Patient?family=foo', headers: { 'Authorization': "Bearer #{@token.token}" }
    assert_response :ok
    json_response = JSON.parse(response.body)
    assert_equal 'Bundle', json_response['resourceType']
    assert_equal 0, json_response['total']
  end

  test 'should find Patient via search on given' do
    get '/fhir/r4/Patient?given=Chris32', headers: { 'Authorization': "Bearer #{@token.token}" }
    assert_response :ok
    json_response = JSON.parse(response.body)
    assert_equal 'Bundle', json_response['resourceType']
    assert_equal 1, json_response['total']
    assert_equal 2, json_response['entry'].first['resource']['id']
  end

  test 'should find Patient via search on telecom' do
    get '/fhir/r4/Patient?telecom=%28555%29%20555-0141', headers: { 'Authorization': "Bearer #{@token.token}" }
    assert_response :ok
    json_response = JSON.parse(response.body)
    assert_equal 'Bundle', json_response['resourceType']
    assert_equal 1, json_response['total']
    assert_equal 2, json_response['entry'].first['resource']['id']
  end

  test 'should find Patient via search on email' do
    get '/fhir/r4/Patient?email=grazyna%40example.com', headers: { 'Authorization': "Bearer #{@token.token}" }
    assert_response :ok
    json_response = JSON.parse(response.body)
    assert_equal 'Bundle', json_response['resourceType']
    assert_equal 1, json_response['total']
    assert_equal 2, json_response['entry'].first['resource']['id']
  end

  test 'should be bad request via search' do
    get '/fhir/r4/FooBar?email=grazyna%40example.com', headers: { 'Authorization': "Bearer #{@token.token}" }
    assert_response :bad_request
  end

  test 'should be unauthorized via all' do
    get '/fhir/r4/Patient/1/$everything'
    assert_response :unauthorized
  end

  test 'should get Bundle via all' do
    get '/fhir/r4/Patient/1/$everything', headers: { 'Authorization': "Bearer #{@token.token}" }
    assert_response :ok
    json_response = JSON.parse(response.body)
    assert_equal 'Bundle', json_response['resourceType']
    assert_equal 5, json_response['total']
    assert_equal 1, json_response['entry'].filter{ |e| e['resource']['resourceType'] == 'Patient' }.count
    assert_equal 2, json_response['entry'].filter{ |e| e['resource']['resourceType'] == 'QuestionnaireResponse' }.count
    assert_equal 2, json_response['entry'].filter{ |e| e['resource']['resourceType'] == 'Observation' }.count
    assert_equal 'Patient/1', json_response['entry'].filter{ |e| e['resource']['resourceType'] == 'Observation' }.first['resource']['subject']['reference']
    assert_equal 'Patient/1', json_response['entry'].filter{ |e| e['resource']['resourceType'] == 'QuestionnaireResponse' }.first['resource']['subject']['reference']
    assert_equal 1, json_response['entry'].first['resource']['id']
  end

  test 'should be forbidden via all' do
    get '/fhir/r4/Patient/9/$everything', headers: { 'Authorization': "Bearer #{@token.token}" }
    assert_response :forbidden
  end

  test 'should get CapabilityStatement unauthorized via capability_statement' do
    get '/fhir/r4/CapabilityStatement'
    json_response = JSON.parse(response.body)
    assert_response :ok
    assert_equal ADMIN_OPTIONS['version'], json_response['software']['version']
  end

  test 'should get CapabilityStatement authorized via capability_statement' do
    get '/fhir/r4/CapabilityStatement', headers: { 'Authorization': "Bearer #{@token.token}" }
    assert_response :ok
    assert_equal ADMIN_OPTIONS['version'], json_response['software']['version']
  end
end
