# frozen_string_literal: true

FactoryBot.define do
  factory :reported_condition, parent: :condition, class: 'ReportedCondition' do
    type { 'ReportedCondition' }
  end
end
