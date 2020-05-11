# frozen_string_literal: true

# Helper methods for the patient model
module PatientHelper # rubocop:todo Metrics/ModuleLength

  # Given a language string, try to find the corresponding BCP 47 code for it
  def language_coding(language)
    languages = {
      'arabic': {code: 'ar', display: 'Arabic', system: 'urn:ietf:bcp:47'},
      'bengali': {code: 'bn', display: 'Bengali', system: 'urn:ietf:bcp:47'},
      'czech': {code: 'cs', display: 'Czech', system: 'urn:ietf:bcp:47'},
      'danish': {code: 'da', display: 'Danish', system: 'urn:ietf:bcp:47'},
      'german': {code: 'de', display: 'German', system: 'urn:ietf:bcp:47'},
      'greek': {code: 'el', display: 'Greek', system: 'urn:ietf:bcp:47'},
      'english': {code: 'en', display: 'English', system: 'urn:ietf:bcp:47'},
      'spanish': {code: 'es', display: 'Spanish', system: 'urn:ietf:bcp:47'},
      'finnish': {code: 'fi', display: 'Finnish', system: 'urn:ietf:bcp:47'},
      'french': {code: 'fr', display: 'French', system: 'urn:ietf:bcp:47'},
      'frysian': {code: 'fy', display: 'Frysian', system: 'urn:ietf:bcp:47'},
      'hindi': {code: 'hi', display: 'Hindi', system: 'urn:ietf:bcp:47'},
      'croatian': {code: 'hr', display: 'Croatian', system: 'urn:ietf:bcp:47'},
      'italian': {code: 'it', display: 'Italian', system: 'urn:ietf:bcp:47'},
      'japanese': {code: 'ja', display: 'Japanese', system: 'urn:ietf:bcp:47'},
      'korean': {code: 'ko', display: 'Korean', system: 'urn:ietf:bcp:47'},
      'dutch': {code: 'nl', display: 'Dutch', system: 'urn:ietf:bcp:47'},
      'norwegian': {code: 'no', display: 'Norwegian', system: 'urn:ietf:bcp:47'},
      'punjabi': {code: 'pa', display: 'Punjabi', system: 'urn:ietf:bcp:47'},
      'polish': {code: 'pl', display: 'Polish', system: 'urn:ietf:bcp:47'},
      'portuguese': {code: 'pt', display: 'Portuguese', system: 'urn:ietf:bcp:47'},
      'russian': {code: 'ru', display: 'Russian', system: 'urn:ietf:bcp:47'},
      'serbian': {code: 'sr', display: 'Serbian', system: 'urn:ietf:bcp:47'},
      'swedish': {code: 'sv', display: 'Swedish', system: 'urn:ietf:bcp:47'},
      'telegu': {code: 'te', display: 'Telegu', system: 'urn:ietf:bcp:47'},
      'chinese': {code: 'zh', display: 'Chinese', system: 'urn:ietf:bcp:47'}
    }
    languages[language&.downcase&.to_sym] ? FHIR::Coding.new( **languages[language&.downcase&.to_sym] ) : nil
  end

  # Build a FHIR US Core Race Extension given Sara Alert race booleans.
  def us_core_race(white, black_or_african_american, american_indian_or_alaska_native, asian, native_hawaiian_or_other_pacific_islander)
    # Don't return an extension if all race categories are false or nil
    return nil unless [white, black_or_african_american, american_indian_or_alaska_native, asian, native_hawaiian_or_other_pacific_islander].include?(true)

    # Build out extension based on what race categories are true
    FHIR::Extension.new(url: 'http://hl7.org/fhir/us/core/StructureDefinition/us-core-race', extension: [
        white ? FHIR::Extension.new(
          url: 'ombCategory',
          valueCoding: FHIR::Coding.new(code: '2106-3', system: 'urn:oid:2.16.840.1.113883.6.238', display: 'White')
        ) : nil,
        black_or_african_american ? FHIR::Extension.new(
          url: 'ombCategory',
          valueCoding: FHIR::Coding.new(code: '2054-5', system: 'urn:oid:2.16.840.1.113883.6.238', display: 'Black or African American')
        ) : nil,
        american_indian_or_alaska_native ? FHIR::Extension.new(
          url: 'ombCategory',
          valueCoding: FHIR::Coding.new(code: '1002-5', system: 'urn:oid:2.16.840.1.113883.6.238', display: 'American Indian or Alaska Native')
        ) : nil,
        asian ? FHIR::Extension.new(
          url: 'ombCategory',
          valueCoding: FHIR::Coding.new(code: '2028-9', system: 'urn:oid:2.16.840.1.113883.6.238', display: 'Asian')
        ) : nil,
        native_hawaiian_or_other_pacific_islander ? FHIR::Extension.new(
          url: 'ombCategory',
          valueCoding: FHIR::Coding.new(code: '2076-8', system: 'urn:oid:2.16.840.1.113883.6.238', display: 'Native Hawaiian or Other Pacific Islander')
        ) : nil,
        FHIR::Extension.new(
          url: 'text',
          valueString: [white ? 'White' : nil,
                        black_or_african_american ? 'Black or African American' : nil,
                        american_indian_or_alaska_native ? 'American Indian or Alaska Native' : nil,
                        asian ? 'Asian' : nil,
                        native_hawaiian_or_other_pacific_islander ? 'Native Hawaiian or Other Pacific Islander' : nil].reject(&:nil?).join(', ')
        )
      ].reject(&:nil?)
    )
  end

  # Return a boolean indicating if the given race code is present on the given FHIR::Patient.
  def self.has_race_code(patient, code)
    patient&.extension&.select{|e| e.url.include?('us-core-race')}&.first&.extension&.select{|e| e.url == 'ombCategory'}&.first&.valueCoding&.code == code
  end

  # Build a FHIR US Core Ethnicity Extension given Sara Alert ethnicity information.
  def us_core_ethnicity(ethnicity)
    # Don't return an extension if no ethnicity specified
    return nil unless ['Hispanic or Latino', 'Not Hispanic or Latino'].include?(ethnicity)

    # Build out extension based on what ethnicity was specified
    FHIR::Extension.new(url: 'http://hl7.org/fhir/us/core/StructureDefinition/us-core-ethnicity', extension: [
        ethnicity == 'Hispanic or Latino' ? FHIR::Extension.new(
          url: 'ombCategory',
          valueCoding: FHIR::Coding.new(code: '2135-2', system: 'urn:oid:2.16.840.1.113883.6.238', display: 'Hispanic or Latino')
        ) : nil,
        ethnicity == 'Not Hispanic or Latino' ? FHIR::Extension.new(
          url: 'ombCategory',
          valueCoding: FHIR::Coding.new(code: '2186-5', system: 'urn:oid:2.16.840.1.113883.6.238', display: 'Not Hispanic or Latino')
        ) : nil,
        FHIR::Extension.new(
          url: 'text',
          valueString: ethnicity
        )
      ]
    )
  end

  # Return a string representing the ethnicity of the given FHIR::Patient
  def self.ethnicity(patient)
    code = patient&.extension&.select{|e| e.url.include?('us-core-ethnicity')}&.first&.extension&.select{|e| e.url == 'ombCategory'}&.first&.valueCoding&.code
    return 'Hispanic or Latino' if code == '2135-2'
    return 'Not Hispanic or Latino' if code == '2186-5'
    nil
  end

  # Build a FHIR US Core BirthSex Extension given Sara Alert sex information.
  def us_core_birthsex(sex)
    # Don't return an extension if no sex specified
    return nil unless ['Male', 'Female', 'Unknown'].include?(sex)

    # Build out extension based on what sex was specified
    code = sex == 'Unknown' ? 'UNK' : sex.first
    FHIR::Extension.new(url: 'http://hl7.org/fhir/us/core/StructureDefinition/us-core-birthsex', valueCode: code)
  end

  # Return a string representing the birthsex of the given FHIR::Patient
  def self.birthsex(patient)
    code = patient&.extension&.select{|e| e.url.include?('us-core-birthsex')}&.first&.valueCode
    return 'Male' if code == 'M'
    return 'Female' if code == 'F'
    return 'Unknown' if code == 'UNK'
    nil
  end

  def normalize_state_names(pat)
    # This list contains all of the same states listed in app/javascript/components/data.js
    state_names = {
      'alabama' => 'Alabama',
      'alaska' => 'Alaska',
      'americansamoa' => 'American Samoa',
      'arizona' => 'Arizona',
      'arkansas' => 'Arkansas',
      'california' => 'California',
      'colorado' => 'Colorado',
      'connecticut' => 'Connecticut',
      'delaware' => 'Delaware',
      'districtofcolombia' => 'District of Columbia',
      'federatedstatesofmicronesia' => 'Federated States of Micronesia',
      'florida' => 'Florida',
      'georgia' => 'Georgia',
      'guam' => 'Guam',
      'hawaii' => 'Hawaii',
      'idaho' => 'Idaho',
      'illinois' => 'Illinois',
      'indiana' => 'Indiana',
      'iowa' => 'Iowa',
      'kansas' => 'Kansas',
      'kentucky' => 'Kentucky',
      'louisiana' => 'Louisiana',
      'maine' => 'Maine',
      'marshallislands' => 'Marshall Islands',
      'maryland' => 'Maryland',
      'massachusetts' => 'Massachusetts',
      'michigan' => 'Michigan',
      'minnesota' => 'Minnesota',
      'mississippi' => 'Mississippi',
      'missouri' => 'Missouri',
      'montana' => 'Montana',
      'nebraska' => 'Nebraska',
      'nevada' => 'Nevada',
      'newhampshire' => 'New Hampshire',
      'newjersey' => 'New Jersey',
      'newmexico' => 'New Mexico',
      'newyork' => 'New York',
      'northcarolina' => 'North Carolina',
      'northdakota' => 'North Dakota',
      'northernmarianaislands' => 'Northern Mariana Islands',
      'ohio' => 'Ohio',
      'oklahoma' => 'Oklahoma',
      'oregon' => 'Oregon',
      'palau' => 'Palau',
      'pennsylvania' => 'Pennsylvania',
      'puertorico' => 'Puerto Rico',
      'rhodeisland' => 'Rhode Island',
      'southcarolina' => 'South Carolina',
      'southdakota' => 'South Dakota',
      'tennessee' => 'Tennessee',
      'texas' => 'Texas',
      'utah' => 'Utah',
      'vermont' => 'Vermont',
      'virginislands' => 'Virgin Islands',
      'virginia' => 'Virginia',
      'washington' => 'Washington',
      'westvirginia' => 'West Virginia',
      'wisconsin' => 'Wisconsin',
      'wyoming' => 'Wyoming'
    }
    pat.monitored_address_state = state_names[normalize_name(pat.monitored_address_state)] || pat.monitored_address_state
    pat.address_state = state_names[normalize_name(pat.address_state)] || pat.address_state
    adpt = pat.additional_planned_travel_destination_state
    pat.additional_planned_travel_destination_state = state_names[normalize_name(adpt)] || adpt
  end

  def normalize_name(name)
    return nil if name.nil?

    name.delete(" \t\r\n").downcase
  end

  def timezone_for_state(name)
    timezones = {
      'alabama' => '-05:00',
      'alaska' => '-08:00',
      'americansamoa' => '-11:00',
      'arizona' => '-07:00',
      'arkansas' => '-05:00',
      'california' => '-07:00',
      'colorado' => '-06:00',
      'connecticut' => '-04:00',
      'delaware' => '-04:00',
      'districtofcolombia' => '-04:00',
      'federatedstatesofmicronesia' => '+11:00',
      'florida' => '-04:00',
      'georgia' => '-04:00',
      'guam' => '+10:00',
      'hawaii' => '-10:00',
      'idaho' => '-06:00',
      'illinois' => '-05:00',
      'indiana' => '-04:00',
      'iowa' => '-05:00',
      'kansas' => '-05:00',
      'kentucky' => '-04:00',
      'louisiana' => '-05:00',
      'maine' => '-04:00',
      'marshallislands' => '+12:00',
      'maryland' => '-04:00',
      'massachusetts' => '-04:00',
      'michigan' => '-04:00',
      'minnesota' => '-05:00',
      'mississippi' => '-05:00',
      'missouri' => '-05:00',
      'montana' => '-06:00',
      'nebraska' => '-05:00',
      'nevada' => '-07:00',
      'newhampshire' => '-04:00',
      'newjersey' => '-04:00',
      'newmexico' => '-06:00',
      'newyork' => '-04:00',
      'northcarolina' => '-04:00',
      'northdakota' => '-05:00',
      'northernmarianaislands' => '+10:00',
      'ohio' => '-04:00',
      'oklahoma' => '-05:00',
      'oregon' => '-07:00',
      'palau' => '+09:00',
      'pennsylvania' => '-04:00',
      'puertorico' => '-04:00',
      'rhodeisland' => '-04:00',
      'southcarolina' => '-04:00',
      'southdakota' => '-05:00',
      'tennessee' => '-05:00',
      'texas' => '-05:00',
      'utah' => '-06:00',
      'vermont' => '-04:00',
      'virginislands' => '-04:00',
      'virginia' => '-04:00',
      'washington' => '-07:00',
      'westvirginia' => '-04:00',
      'wisconsin' => '-05:00',
      'wyoming' => '-06:00',
      nil => '-04:00',
      '' => '-04:00'
    }
    timezones[normalize_name(name)] || '-04:00'
  end
end
