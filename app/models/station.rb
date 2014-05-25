class Station < ActiveRecord::Base
  validates :name, presence: true, uniqueness: true
  validates :code, presence: true, uniqueness: true

  def self.valid_station_codes
    all.collect{|station| station.code}
  end

  def self.get_stations
    all.each.inject({}) {|list, station| list["#{station.name} (#{station.code})"] = station.code; list}.sort
  end
end
