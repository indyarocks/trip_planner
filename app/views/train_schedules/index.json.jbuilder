json.array!(@train_schedules) do |train_schedule|
  json.extract! train_schedule, :id, :train_number, :station_code, :distance_from_origin, :arrival_time, :departure_time, :sun, :mon, :tue, :wed, :thu, :fri, :sat, :journey_day
  json.url train_schedule_url(train_schedule, format: :json)
end
