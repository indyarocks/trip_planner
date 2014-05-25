json.array!(@stations) do |station|
  json.extract! station, :id, :name, :code
  json.url station_url(station, format: :json)
end
