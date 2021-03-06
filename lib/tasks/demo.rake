# frozen_string_literal: true

namespace :demo do
  desc 'Configure the database for demo use'
  task setup: :environment do
    raise 'This task is only for use in a development environment' unless Rails.env == 'development'

    #####################################

    print 'Creating jurisdictions...'

    usa = Jurisdiction.where(name: 'USA').first
    state1 = Jurisdiction.where(name: 'State 1').first
    state2 = Jurisdiction.where(name: 'State 2').first
    county1 = Jurisdiction.where(name: 'County 1').first
    county2 = Jurisdiction.where(name: 'County 2').first
    county3 = Jurisdiction.where(name: 'County 3').first
    county4 = Jurisdiction.where(name: 'County 4').first

    puts ' done!'

    #####################################

    print 'Creating enroller users...'

    enroller1 = User.new(email: 'state1_enroller@example.com', password: '1234567ab!', jurisdiction: state1, force_password_change: false, authy_enabled: false, authy_enforced: false)
    enroller1.add_role :enroller
    enroller1.save

    enroller2 = User.new(email: 'localS1C1_enroller@example.com', password: '1234567ab!', jurisdiction: county1, force_password_change: false, authy_enabled: false, authy_enforced: false)
    enroller2.add_role :enroller
    enroller2.save

    enroller3 = User.new(email: 'localS1C2_enroller@example.com', password: '1234567ab!', jurisdiction: county2, force_password_change: false, authy_enabled: false, authy_enforced: false)
    enroller3.add_role :enroller
    enroller3.save

    enroller4 = User.new(email: 'state2_enroller@example.com', password: '1234567ab!', jurisdiction: state2, force_password_change: false, authy_enabled: false, authy_enforced: false)
    enroller4.add_role :enroller
    enroller4.save

    enroller5 = User.new(email: 'localS2C3_enroller@example.com', password: '1234567ab!', jurisdiction: county3, force_password_change: false, authy_enabled: false, authy_enforced: false)
    enroller5.add_role :enroller
    enroller5.save

    enroller6 = User.new(email: 'localS2C4_enroller@example.com', password: '1234567ab!', jurisdiction: county4, force_password_change: false, authy_enabled: false, authy_enforced: false)
    enroller6.add_role :enroller
    enroller6.save

    puts ' done!'

    #####################################

    print 'Creating public health users...'

    ph1 = User.new(email: 'state1_epi@example.com', password: '1234567ab!', jurisdiction: state1, force_password_change: false, authy_enabled: false, authy_enforced: false)
    ph1.add_role :public_health
    ph1.save

    ph2 = User.new(email: 'localS1C1_epi@example.com', password: '1234567ab!', jurisdiction: county1, force_password_change: false, authy_enabled: false, authy_enforced: false)
    ph2.add_role :public_health
    ph2.save

    ph3 = User.new(email: 'localS1C2_epi@example.com', password: '1234567ab!', jurisdiction: county2, force_password_change: false, authy_enabled: false, authy_enforced: false)
    ph3.add_role :public_health
    ph3.save

    ph4 = User.new(email: 'state2_epi@example.com', password: '1234567ab!', jurisdiction: state2, force_password_change: false, authy_enabled: false, authy_enforced: false)
    ph4.add_role :public_health
    ph4.save

    ph5 = User.new(email: 'localS2C3_epi@example.com', password: '1234567ab!', jurisdiction: county3, force_password_change: false, authy_enabled: false, authy_enforced: false)
    ph5.add_role :public_health
    ph5.save

    ph6 = User.new(email: 'localS2C4_epi@example.com', password: '1234567ab!', jurisdiction: county4, force_password_change: false, authy_enabled: false, authy_enforced: false)
    ph6.add_role :public_health
    ph6.save

    puts ' done!'

    #####################################

    print 'Creating public health enroller users...'

    phe1 = User.new(email: 'state1_epi_enroller@example.com', password: '1234567ab!', jurisdiction: state1, force_password_change: false, authy_enabled: false, authy_enforced: false)
    phe1.add_role :public_health_enroller
    phe1.save

    puts ' done!'

    #####################################

    print 'Creating admin users...'

    admin1 = User.new(email: 'admin1@example.com', password: '1234567ab!', jurisdiction: usa, force_password_change: false, authy_enabled: false, authy_enforced: false)
    admin1.add_role :admin
    admin1.save

    puts ' done!'

    #####################################

    print 'Creating analyst users...'

    analyst1 = User.new(email: 'analyst_all@example.com', password: '1234567ab!', jurisdiction: usa, force_password_change: false, authy_enabled: false, authy_enforced: false)
    analyst1.add_role :analyst
    analyst1.save

    puts ' done!'

    #####################################
  end

  desc 'Add lots of data to the database to provide some idea of basic scaling issues'
  task populate: :environment do
    raise 'This task is only for use in a development environment' unless Rails.env == 'development'

    days = (ENV['DAYS'] || 14).to_i
    count = (ENV['COUNT'] || 25).to_i
    perform_daily_analytics_update = (ENV['SKIP_ANALYTICS'] != 'true')

    enrollers = User.all.select { |u| u.has_role?('enroller') }

    assessment_columns = Assessment.column_names - %w[id created_at updated_at patient_id symptomatic who_reported]
    all_false = assessment_columns.each_with_object({}) { |column, hash| hash[column] = false }

    jurisdictions = Jurisdiction.all
    Analytic.delete_all

    # foobar added to list to test "unknown" locations
    territory_names = ['American Samoa',
      'District of Columbia',
      'Federated States of Micronesia',
      'Guam',
      'Marshall Islands',
      'Northern Mariana Islands',
      'Palau',
      'Puerto Rico',
      'Virgin Island',
      'foobar']

    days.times do |day|
      today = Date.today - (days - (day + 1)).days
      # Create the patients for this day
      printf("Simulating day #{day + 1} (#{today}):\n")

      # Transaction speeds things up a bit
      Patient.transaction do
      
        # Create assessments for 80-90% of patients on any given day
        printf("Generating assessments...")
        patients = Patient.where('created_at <= ?', today)
        patient_ids_assessment = patients.pluck(:id).sample(patients.count * rand(80..90) / 100)
        pcount_assessment = patient_ids_assessment.length
        Patient.find(patient_ids_assessment).each_with_index do |patient, index|
          next if patient.assessments.any? { |a| a.created_at.to_date == today }
          printf("\rGenerating assessment #{index+1} of #{pcount_assessment}...")
          reported_condition = patient.jurisdiction.hierarchical_condition_unpopulated_symptoms
          assessment = Assessment.new
          if rand < 0.3 # 30% report some sort of symptoms
            bool_symps = reported_condition.symptoms.select {|s| s.type == "BoolSymptom" }
            number_of_symptoms = rand(bool_symps.count) + 1
            bool_symps.each do |symp|  symp['bool_value'] = false end
            bool_symps.shuffle[0,number_of_symptoms].each do |symp| symp['bool_value'] = true end
            assessment.update(reported_condition: reported_condition, created_at: Faker::Time.between_dates(from: today, to: today, period: :day))
            # Outside the context of the demo script, an assessment would already have a threshold condition saved to check the symptomatic status
            # We'll compensate for that here by just re-updating
            assessment.update(symptomatic: assessment.symptomatic?)
            patient.assessments << assessment
            patient.save
          else
            bool_symps = reported_condition.symptoms.select {|s| s.type == "BoolSymptom" }
            bool_symps.each do |symp|  symp['bool_value'] = false end
            assessment.update(reported_condition: reported_condition, symptomatic: false, created_at: Faker::Time.between_dates(from: today, to: today, period: :day))
            assessment.save
            patient.assessments << assessment
            patient.save
          end
          patient.refresh_symptom_onset(assessment.id)
        end
        printf(" done.\n")

        # Create laboratories for 10-20% of isolation patients on any given day
        printf("Generating laboratories...")
        isol_patients = Patient.where(isolation: true).where('created_at <= ?', today)
        patient_ids_lab = isol_patients.pluck(:id).sample(isol_patients.count * rand(10..20) / 100)
        pcount_lab = patient_ids_lab.length
        Patient.find(patient_ids_lab).each_with_index do |patient, index|
          printf("\rGenerating laboratory #{index+1} of #{pcount_lab}...")
          report_date = Faker::Time.between_dates(from: 1.week.ago, to: today, period: :day)
          lab = Laboratory.new(
            lab_type: ['PCR', 'Antigen', 'IgG Antibody', 'IgM Antibody', 'IgA Antibody'].sample,
            specimen_collection: Faker::Time.between_dates(from: 2.weeks.ago, to: report_date, period: :day),
            report: report_date,
            result: ['positive', 'negative', 'indeterminate', 'other'].sample
          )
          patient.laboratories << lab
          patient.save
        end
        printf(" done.\n")

        # Create count patients
        count.times do |i|
          printf("\rGenerating monitoree #{i+1} of #{count}...")

          sex = Faker::Gender.binary_type
          birthday = Faker::Date.birthday(min_age: 1, max_age: 85)
          risk_factors = rand < 0.9
          isol = rand < 0.30
          monitoring = rand < 0.9
          patient = Patient.new(
            first_name: "#{sex == 'Male' ? Faker::Name.male_first_name : Faker::Name.female_first_name}#{rand(10)}#{rand(10)}",
            middle_name: "#{Faker::Name.middle_name}#{rand(10)}#{rand(10)}",
            last_name: "#{Faker::Name.last_name}#{rand(10)}#{rand(10)}",
            sex: sex,
            date_of_birth: birthday,
            age: ((Date.today - birthday) / 365.25).round,
            ethnicity: rand < 0.82 ? 'Not Hispanic or Latino' : 'Hispanic or Latino',
            primary_language: 'English',
            address_line_1: Faker::Address.street_address,
            address_city: Faker::Address.city,
            address_state: Faker::Address.state,
            address_line_2: rand < 0.3 ? Faker::Address.secondary_address : nil,
            address_zip: Faker::Address.zip_code,
            primary_telephone: '(333) 333-3333',
            primary_telephone_type: rand < 0.7 ? 'Smartphone' : 'Plain Cell',
            secondary_telephone: '(333) 333-3333',
            secondary_telephone_type: 'Landline',
            email: "#{rand(1000000000..9999999999)}fake@example.com",
            preferred_contact_method: "E-mailed Web Link",
            port_of_origin: Faker::Address.city,
            date_of_departure: today - (rand < 0.3 ? 1.day : 0.days),
            source_of_report: rand < 0.4 ? 'Self-Identified' : 'CDC',
            flight_or_vessel_number: "#{('A'..'Z').to_a.sample}#{rand(10)}#{rand(10)}#{rand(10)}",
            flight_or_vessel_carrier: "#{Faker::Name.first_name} Airlines",
            port_of_entry_into_usa: Faker::Address.city,
            date_of_arrival: today,
            last_date_of_exposure: today - rand(5).days,
            potential_exposure_location: rand < 0.7 ? Faker::Address.city : nil,
            potential_exposure_country: rand < 0.8 ? Faker::Address.country: nil,
            contact_of_known_case: risk_factors && rand < 0.3,
            travel_to_affected_country_or_area: risk_factors && rand < 0.1,
            was_in_health_care_facility_with_known_cases: risk_factors && rand < 0.15,
            laboratory_personnel: risk_factors && rand < 0.05,
            healthcare_personnel: risk_factors && rand < 0.2,
            crew_on_passenger_or_cargo_flight: risk_factors && rand < 0.25,
            member_of_a_common_exposure_cohort: risk_factors && rand < 0.1,
            creator: enrollers.sample,
            user_defined_id_statelocal: "EX-#{rand(10)}#{rand(10)}#{rand(10)}#{rand(10)}#{rand(10)}#{rand(10)}",
            created_at: Faker::Time.between_dates(from: today, to: today, period: :day),
            isolation: isol,
            case_status: isol ? 'Confirmed' : '',
            monitoring: monitoring,
            closed_at: monitoring ? nil : today
          )

          patient.submission_token = SecureRandom.hex(20)

          patient[%i[white black_or_african_american american_indian_or_alaska_native asian native_hawaiian_or_other_pacific_islander].sample] = true

          if rand < 0.7
            patient.monitored_address_line_1 = patient.address_line_1
            patient.monitored_address_city = patient.address_city
            patient.monitored_address_state = patient.address_state
            patient.monitored_address_line_2 = patient.address_line_2
            patient.monitored_address_zip = patient.address_zip
          else
            if rand > 0.5
              state = Faker::Address.state
            else
              state = territory_names[rand(territory_names.count)]
            end
            patient.monitored_address_line_1 = Faker::Address.street_address
            patient.monitored_address_city = Faker::Address.city
            patient.monitored_address_state = state
            patient.monitored_address_line_2 = rand < 0.3 ? Faker::Address.secondary_address : nil
            patient.monitored_address_zip = Faker::Address.zip_code
          end

          if rand < 0.3
            patient.additional_planned_travel_type = rand < 0.7 ? 'Domestic' : 'International'
            patient.additional_planned_travel_destination = Faker::Address.city
            patient.additional_planned_travel_destination_state = Faker::Address.city if patient.additional_planned_travel_type == 'Domestic'
            patient.additional_planned_travel_destination_country = Faker::Address.country if patient.additional_planned_travel_type == 'International'
            patient.additional_planned_travel_port_of_departure = Faker::Address.city
            patient.additional_planned_travel_start_date = today + rand(6).days
            patient.additional_planned_travel_end_date = patient.additional_planned_travel_start_date + rand(10).days
          end

          if rand < 0.1
            patient.exposure_risk_assessment = 'High'
            patient.monitoring_plan = 'Self-monitoring with delegated supervision'
          elsif rand < 0.3
            patient.exposure_risk_assessment = 'Medium'
            patient.monitoring_plan = 'Daily active monitoring'
          elsif rand < 0.55
            patient.exposure_risk_assessment = 'Low'
            patient.monitoring_plan = 'Self-monitoring with public health supervision'
          elsif rand < 0.7
            patient.exposure_risk_assessment = 'No Identified Risk'
            patient.monitoring_plan = 'Self-observation'
          end

          if !isol && rand < 0.15
            patient.public_health_action = [
              'Recommended medical evaluation of symptoms',
              'Document results of medical evaluation',
              'Recommended laboratory testing'
            ].sample
          end

          patient.jurisdiction = jurisdictions.sample
          patient.responder = patient
          patient.save

          history = History.new
          history.created_by = 'Sara Alert System'
          history.comment = 'This synthetic monitoree was randomly generated.'
          history.patient = patient
          history.history_type = 'Enrollment'
          history.save
        end
        printf(" done.\n")

        # Cases increase 10-20% every day
        count += (count * (0.1 + (rand / 10))).round

        # Run the analytics cache update at the end of each simulation day, or only on final day if SKIP is set.
        if perform_daily_analytics_update || (day + 1) == days
          printf("Caching analytics...")
          before_analytics_count = Analytic.count
          Rake::Task["analytics:cache_current_analytics"].reenable
          Rake::Task["analytics:cache_current_analytics"].invoke
          after_analytics_count = Analytic.count
          # Add time onto update time for more realistic reports
          t = Time.now
          date_time_update = DateTime.new(today.year, today.month, today.day, t.hour, t.min, t.sec, t.zone)
          Analytic.all.order(:id)[before_analytics_count..after_analytics_count].each do |analytic|
            analytic.update!(created_at: date_time_update, updated_at: date_time_update)
          end
          printf(" done.\n")
        end

      end
      printf("\n")
    end
  end
end
