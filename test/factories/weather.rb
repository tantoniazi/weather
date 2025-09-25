FactoryBot.define do
  factory :weather do
    zip { "12345" }
    temperature { 25.0 }
    temp_min { 22.0 }
    temp_max { 28.0 }
    description { "céu limpo" }
    association :user
  end
end
