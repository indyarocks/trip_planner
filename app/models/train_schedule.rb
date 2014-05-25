class TrainSchedule < ActiveRecord::Base
  validates :train_number, inclusion: { in: Train.valid_train_numbers, :message => "Invalid train number."}
  validates :station_code, inclusion: { in: Station.valid_station_codes, :message => "Invalid station code."}

  validates_uniqueness_of :train_number, scope: :station_code, message: "The train number and station code combination already exists."

  validates :sun, :mon, :tue, :wed, :thu, :fri, :sat, :inclusion => {:in => [true, false], :message => "Invalid weekday input" }
  validates :journey_day, numericality: { greater_than_or_equal_to: 1, :message => "Journey day must be greater than or equal to 1."}


  VALID_TIME_FORMAT_REGEX = /\A(([0-9]|0[0-9]|1[0-9]|2[0-3]):[0-5][0-9])|(n\/a)\z/i
  validates :arrival_time, format: { with: VALID_TIME_FORMAT_REGEX, :message => "Arrival time must be a valid time in HH:MM format or N/A for origin"}
  validates :departure_time, format: { with: VALID_TIME_FORMAT_REGEX, :message => "Departure time must be a valid time in HH:MM format or N/A for end point"}

  VALID_TRIP_TYPES = %w(one_way return multi_part).freeze

  WDAY_DAY_MAP = { 0 => 'sun', 1 => 'mon', 2 => 'tue', 3 => 'wed', 4 => 'thu', 5 => 'fri', 6 => 'sat'}.freeze


  # Method to find the trip details
  #
  # <b>Expects</b>
  #   <b>Hash[:trip_type]</b> <em>(String)</em> - Valid trip type from VALID_TRIP_TYPES
  #   <b>Hash[:origin]</b> <em>(String)</em> - Valid station code - for one-way and return journey
  #   <b>Hash[:origin_1]</b> <em>(String)</em> - Valid station code - for multi-part journey
  #   <b>Hash[:origin_2]</b> <em>(String)</em> - Valid station code - for multi-part journey
  #   <b>Hash[:destination]</b> <em>(String)</em> - Valid station code - for one-way and return journey
  #   <b>Hash[:destination_1]</b> <em>(String)</em> - Valid station code - for multi-part journey
  #   <b>Hash[:destination_2]</b> <em>(String)</em> - Valid station code - for multi-part journey
  #   <b>Hash[:depart_date]</b> <em>(String)</em> - Valid depart date - for one-way and return journey
  #   <b>Hash[:depart_date_1]</b> <em>(String)</em> - Valid depart date - for multi-part journey
  #   <b>Hash[:depart_date_2]</b> <em>(String)</em> - Valid depart date - for multi-part journey
  #
  # <b>Returns</b>
  #   <b>Hash[:trip_details][:single_trains]</b> <em>(Array)</em> Array of single trip details
  #   <b>Hash[:trip_details][:multi_part]</b><em>(Array)</em> Array of Array having multi part trip details
  #   <b>Hash[:err]</b><em>(String)</em> Error code, if any
  #   <b>Hash[:message]</b><em>(String)</em> Error message, if any
  #
  #
  def self.find_suitable_trip_schedule(params)
    begin
      if VALID_TRIP_TYPES.include? params[:trip_type]
        response = eval("find_#{params[:trip_type]}_trip_schedule(#{params})")
        result = {trip_details: response[:trip_details], err: response[:err], message: response[:message]}
      else
        result = {trip_details: {}, err: 'err1', message: 'Invalid trip type.'}
      end
    rescue Exception => e
      result = {trip_details: {}, err: 'err007', message: "Something went wrong. Please contact developer.\n\n BACKTRACE: #{e.backtrace}\n\n ERROR MESSAGE: #{e.message}"}
    end

    return result.merge(trip_type: params[:trip_type])
  end


  # Method to find one way trip schedule.
  def self.find_one_way_trip_schedule(params)
    params = recursively_symbolize_params(params)

    return {trip_details: {one_way: {}}, err: 'err0', message: 'Please provide all required fields.'} if params[:origin].blank? or params[:destination].blank? or params[:depart_date].blank?

    trip_data = find_trip_schedule_for_given_date(origin: params[:origin], destination: params[:destination], depart_date: params[:depart_date])

    trip_details = format_trip_schedule(available_train_schedules: trip_data[:trip_details], depart_date: params[:depart_date])


    return {trip_details: {one_way: trip_details}, err: trip_data[:err], message: trip_data[:message]}
  end

  # Method to find return trip schedule
  # ASSUMPTION: For return journey, constraint will be put only return date but not the arrival time of onward journey train
  def self.find_return_trip_schedule(params)
    params = recursively_symbolize_params(params)
    if [params[:origin], params[:destination], params[:depart_date], params[:return_date]].any?(&:blank?)
      return {trip_details: {onward_journey: {}, return_journey: {}}, err: 'err0', message: 'Please provide all required fields.'}
    end

    onward_journey_data = find_trip_schedule_for_given_date(origin: params[:origin], destination: params[:destination], depart_date: params[:depart_date])

    if onward_journey_data[:err].present?
      return {trip_details: {onward_journey: {}, return_journey: {}}, err: onward_journey_data[:err], message: ('ONWARD JOURNEY:' + onward_journey_data[:message])}
    end

    return_journey_data = find_trip_schedule_for_given_date(origin: params[:destination], destination: params[:origin], depart_date: params[:return_date])
    if return_journey_data[:err].present?
      return {trip_details: {onward_journey: {}, return_journey: {}}, err: return_journey_data[:err], message: ('RETURN JOURNEY:' + return_journey_data[:message])}
    end

    onward_trip_details = format_trip_schedule(available_train_schedules: onward_journey_data[:trip_details], depart_date: params[:depart_date], date_constraint: params[:return_date])

    if onward_trip_details[:single_trains].blank? && onward_trip_details[:multi_part].blank?
      return {trip_details: {onward_journey: {}, return_journey: {}}, err: 'err1', message: 'No train combination found for the given date.'}
    end

    return_trip_details = format_trip_schedule(available_train_schedules: return_journey_data[:trip_details], depart_date: params[:return_date])

    return {trip_details: {onward_journey: onward_trip_details, return_journey: return_trip_details}, err: '', message: ''}
  end

  # Method to find multi part trip schedule
  def self.find_multi_part_trip_schedule(params)
    params = recursively_symbolize_params(params)

    if [params[:origin_1], params[:destination_1], params[:origin_2], params[:destination_2], params[:depart_date_1], params[:depart_date_2]].any?(&:blank?)
      return {trip_details: {first_part: {}, second_part: {}}, err: 'err0', message: 'Please provide all required fields.'}
    end

    unless params[:destination_1] == params[:origin_2]
      {trip_details: {first_part: {}, second_part: {}}, err: 'err1', message: 'Destination of first part must be same as origin of second part of multi-part journey.'}
    end

    first_part_data = find_trip_schedule_for_given_date(origin: params[:origin_1], destination: params[:destination_1], depart_date: params[:depart_date_1])

    if first_part_data[:err].present?
      return {trip_details: {first_part: {}, second_part: {}}, err: first_part_data[:err], message: ('FIRST JOURNEY:' + first_part_data[:message])}
    end

    second_part_data = find_trip_schedule_for_given_date(origin: params[:origin_2], destination: params[:destination_2], depart_date: params[:depart_date_2])
    if second_part_data[:err].present?
      return {trip_details: {first_part: {}, second_part: {}}, err: second_part_data[:err], message: ('SECOND JOURNEY:' + second_part_data[:message])}
    end

    first_part_details = format_trip_schedule(available_train_schedules: first_part_data[:trip_details], depart_date: params[:depart_date_1], date_constraint: params[:depart_date_2])

    if first_part_details[:single_trains].blank? && first_part_details[:multi_part].blank?
      return {trip_details: {first_part: {}, second_part: {}}, err: 'err2', message: 'No train combination found for the given dates.'}
    end

    second_part_details = format_trip_schedule(available_train_schedules: second_part_data[:trip_details], depart_date: params[:depart_date_2])

    return {trip_details: {first_part: first_part_details, second_part: second_part_details}, err: '', message: ''}
  end

  # Method to find possible trains for a given origin and destination and departure date
  #
  # <b>Expects</b>
  #   *<b>Hash[:origin]</b> <em>(String)</em> - Valid station code
  #   *<b>Hash[:destination]</b> <em>(String)</em> - Valid station code
  #   *<b>Hash[:depart_date]</b> <em>(String)</em> - Valid depart date
  #
  # <b>Returns</b>
  #   *<b>Hash[:trip_details][:single_trains]</b> <em>(Array)</em> - TrainSchedule Actice Record, origin and destination
  #   *<b>Hash[:trip_details][:multi_part]</b> <em>(Array)</em> - TrainSchedule Actice Record hash with origin, destination in order
  #   *<b>Hash[:err]</b> <em>(String)</em> - Error code
  #   *<b>Hash[:message]</b> <em>(String)</em> - Error message
  #
  # <b>Errors</b>
  #
  # ASSUMPTION:
  #  1. We want maximum upto 2 joining train to reach from origin to destination
  #  2. A train will have same time schedule for all days of week.
  def self.find_trip_schedule_for_given_date(params)
    possible_single_train_schedules, possible_multi_part_train_schedules = [], []
    trip_details = {single_trains: [], multi_part: []}
    if [params[:origin], params[:destination], params[:depart_date]].any?(&:blank?)
      return {trip_details: trip_details, err: 'err11', message: 'Mandatory field missing.'}
    end

    weekday = get_weekday(params[:depart_date])

    possible_origin_trains = TrainSchedule.where("station_code = ? AND #{weekday} = ?", params[:origin], true).all.index_by(&:train_number)

    return {trip_details: trip_details, err: 'err12', message: "No train starting from the given origin station #{params[:origin]} for this date."} if possible_origin_trains.blank?

    possible_destination_trains = TrainSchedule.where("station_code = ? AND distance_from_origin != ?", params[:destination], 0).all.index_by(&:train_number)

    return {trip_details: trip_details, err: 'err13', message: "No train for the given destination #{params[:destination]}."} if possible_destination_trains.blank?

    # Find all single train fulfilling the criteria, list them
    (possible_origin_trains.keys & possible_destination_trains.keys).each do |single_train_number|
      # A train can go from origin to destination only if the distance_from_origin for destination is greater
      if possible_origin_trains[single_train_number].distance_from_origin < possible_destination_trains[single_train_number].distance_from_origin
        possible_single_train_schedules << {origin: possible_origin_trains[single_train_number], destination: possible_destination_trains[single_train_number]}
      end
      possible_origin_trains.delete(single_train_number)
      possible_destination_trains.delete(single_train_number)
    end

    # Fetch all possible stops for origin trains in single query
    possible_origin_train_stops = TrainSchedule.where(train_number: possible_origin_trains.keys).all

    # Fetch all possible stops for destination trains in single query
    possible_destination_train_stops = TrainSchedule.where(train_number: possible_destination_trains.keys).all

    # collect valid stops for origin train in a hash with key as train number.
    origin_train_number_stops_map = {}
    possible_origin_train_stops.each do |train_schedule|
      tr_no = train_schedule.train_number
      if train_schedule.distance_from_origin >= possible_origin_trains[tr_no].distance_from_origin
        (origin_train_number_stops_map[tr_no] ||= []).push(train_schedule)
      end
    end

    # restructure origin_train_number_stops_map train_schedule by distance_from_origin, to find first common station for multi-part train
    origin_train_number_stops_map_sorted = Hash[origin_train_number_stops_map.map{|key, val| [key, val.sort_by{|ts| ts.distance_from_origin}]}]

    # Collect valid stops for destination train in a hash with key as train number.
    destination_train_number_stops_map = {}
    possible_destination_train_stops.each do |train_schedule|
      tr_no = train_schedule.train_number
      if train_schedule.distance_from_origin <= possible_destination_trains[tr_no].distance_from_origin
        (destination_train_number_stops_map[tr_no] ||= []).push(train_schedule)
      end
    end

    # restructure destination_train_number_stops_map train_schedule by distance_from_origin, to find first common station for multi-part train
    destination_train_number_stops_map_sorted = Hash[destination_train_number_stops_map.map{|key, val| [key, val.sort_by{|ts| ts.distance_from_origin}]}]

    possible_origin_trains.each do |origin_tr_no, origin_ts|
      ordered_origin_train_stops = origin_train_number_stops_map_sorted[origin_tr_no].collect{|ts| ts.station_code} - [origin_ts.station_code] # Remove the origin train from possible next stops list
      destination_train_number_stops_map_sorted.each do |dest_tr_no, dest_tr_stops|
        trip_found = false
        dest_tr_stops.each do |dest_ts|
          next if trip_found == true
          if (index = ordered_origin_train_stops.index(dest_ts.station_code)).present?
            first_part = {origin: origin_ts, destination: origin_train_number_stops_map_sorted[origin_tr_no][index+1]}
            second_part = {origin: dest_ts, destination: destination_train_number_stops_map_sorted[dest_tr_no].last}
            possible_multi_part_train_schedules << [first_part, second_part]
            trip_found = true
          end
        end
      end
    end

    if possible_single_train_schedules.blank? && possible_multi_part_train_schedules.blank?
      result = {trip_details: {single_trains: possible_single_train_schedules, multi_part: possible_multi_part_train_schedules}, err: 'err14', message: "No train found for the given origin and destination combination"}
    else
      result = {trip_details: {single_trains: possible_single_train_schedules, multi_part: possible_multi_part_train_schedules}, err: '', message: "Check result"}
    end

    return result
  end

  # Method to format the trip schedules
  #
  #
  # <b>Expects</b>
  #   *<b>Hash[available_train_schedules][:single_trains]</b> <em>(Array)</em> - Valid single train train scheules
  #   *<b>Hash[available_train_schedules][:multi_part]</b> <em>(Array)</em> - Valid single train train scheules
  #   *<b>Hash[:depart_date]</b> <em>(String)</em> - Valid depart date
  #    <b>Hash[:date_constraint]</b> <em>(String)</em> - Any date constraint for arrival date (valid for return trip and multi-part trip)
  #
  # <b>Returns</b>
  #   *<b>Hash[:single_trains]</b> <em>(Array)</em> - Array of Hashes having formatted train time table
  #   *<b>Hash[:multi_part]</b> <em>(Array)</em> - Array of Array of Hashes having formatted train time table
  #
  def self.format_trip_schedule(params)
    train_numbers, station_codes, result = [], [], {single_trains: [], multi_part: []}
    return result if params[:available_train_schedules].blank? or params[:depart_date].blank?
    # Collect train_number and station_code for all possible train_schedules in params[:available_train_schedules]
    params[:available_train_schedules][:single_trains].each do |trip_hash|
      trip_hash.each_value do |ts|
        (train_numbers ||= []).push(ts.train_number)
        (station_codes ||= []).push(ts.station_code)
      end
    end

    params[:available_train_schedules][:multi_part].each do |possible_trip_array|
      possible_trip_array.each do |trip_hash|
        trip_hash.each_value do |ts|
          (train_numbers ||= []).push(ts.train_number)
          (station_codes ||= []).push(ts.station_code)
        end
      end
    end

    # Fetch all train name and station name in single query
    train_no_name_map = Train.where(number: train_numbers).select('number, name').index_by(&:number)
    station_code_name_map = Station.where(code: station_codes).select('name, code').index_by(&:code)

    params[:available_train_schedules][:single_trains].each do |trip_hash|
      origin_ts = trip_hash[:origin]
      destination_ts = trip_hash[:destination]
      depart_day = get_weekday(params[:depart_date])
      arrival_date_details = get_next_date_day(params[:depart_date], (destination_ts.journey_day - origin_ts.journey_day))
      # If arrival dates is after the date constraint(for return/multi-part trip), ignore this train schedule
      next if params[:date_constraint].present? && Date.parse(arrival_date_details[:next_date]) > Date.parse(params[:date_constraint])
      result[:single_trains] << {train_name: train_no_name_map[origin_ts.train_number].name,
                                 train_number: origin_ts.train_number,
                                 origin: station_code_name_map[origin_ts.station_code].name,
                                 depart_day: depart_day.humanize,
                                 depart_date: params[:depart_date],
                                 depart_time: origin_ts.departure_time,
                                 destination: station_code_name_map[destination_ts.station_code].name,
                                 arrival_day: arrival_date_details[:next_day].humanize,
                                 arrival_date: arrival_date_details[:next_date],
                                 arrival_time: destination_ts.arrival_time}
    end

    params[:available_train_schedules][:multi_part].each do |possible_trip_array|
      possible_trip_details = []
      possible_trip_array.each_with_index do |trip_hash, i|
        origin_ts = trip_hash[:origin]
        destination_ts = trip_hash[:destination]
        departure_time = origin_ts.departure_time
        if i == 0
          depart_date = params[:depart_date]
          depart_day = get_weekday(params[:depart_date])
        else  # Find possible next date if i != 0 based on earlier part of journey
          next if possible_trip_details.blank? && params[:date_constraint].present?
          earlier_journey_part = possible_trip_details[i - 1]
          available_days = origin_ts.collect_weekdays_for_given_train_schedule
          next_departure_date_details = get_next_possible_date_details(earlier_journey_part[:arrival_date],
                                                            earlier_journey_part[:arrival_time],
                                                            available_days,
                                                            departure_time)
          depart_date, depart_day =  next_departure_date_details[:next_date], next_departure_date_details[:next_day]
        end
        arrival_date_details = get_next_date_day(depart_date, (destination_ts.journey_day - origin_ts.journey_day))
        # If arrival dates is after the date constraint(for return/multi-part trip), ignore this train schedule
        possible_trip_details = [] and next if params[:date_constraint].present? && Date.parse(arrival_date_details[:next_date]) > Date.parse(params[:date_constraint])
        possible_trip_details <<  {train_name: train_no_name_map[origin_ts.train_number].name,
                                   train_number: origin_ts.train_number,
                                   origin: station_code_name_map[origin_ts.station_code].name,
                                   depart_day: depart_day.humanize,
                                   depart_date: depart_date,
                                   depart_time: origin_ts.departure_time,
                                   destination: station_code_name_map[destination_ts.station_code].name,
                                   arrival_day: arrival_date_details[:next_day].humanize,
                                   arrival_date: arrival_date_details[:next_date],
                                   arrival_time: destination_ts.arrival_time}

      end
      result[:multi_part] << possible_trip_details if possible_trip_details.present?
    end

    return result
  end

  # Method to collect the valid weekdays for a given train schedule object
  def collect_weekdays_for_given_train_schedule
    weekdays = []
    WDAY_DAY_MAP.each do |n,d|
      weekdays << n if eval('self[d.to_sym]') == true
    end
    return weekdays
  end


  private
    # Method to get weekday for a given date
    def self.get_weekday(date)
      wd = Date.strptime(date).wday
      WDAY_DAY_MAP[wd]
    end

    def self.recursively_symbolize_params(params)
      HashWithIndifferentAccess.new(params)
    end

    # Method to get next date and weekday given start date and day difference
    def self.get_next_date_day(start_date, delta)
      next_date_obj = (Date.parse(start_date) + delta)
      return {next_date: next_date_obj.strftime('%Y-%m-%d'), next_day: WDAY_DAY_MAP[next_date_obj.wday]}
    end

    # Expects:
    #   arrival_date: "2014-05-29"
    #   arrival_time: "21:15"
    #   available_days: [5,6]
    #   available_time: "15:15"
    # Returns:
    #   next_date:
    #   next_time:
    #   next_day:
    def self.get_next_possible_date_details(arrival_date, arrival_time, available_days, available_time)
      arrival_date_obj = Date.parse(arrival_date)
      arrival_wday = arrival_date_obj.wday
      # Check if next train can depart on arrival_date
      if available_days.include? arrival_wday
        if arrival_time.gsub(':','').to_i < available_time.gsub(':', '').to_i
          return {next_date: arrival_date, next_time: available_time, next_day: WDAY_DAY_MAP[arrival_wday]}
        end
        available_days.delete(arrival_wday) if available_days.count > 1 # Remove this weekday if other weekday is available
      end
      possible_delta = []
      available_days.each do |ad|
        day_difference = (ad - arrival_wday)
        day_difference += 7 if day_difference <= 0
        possible_delta.push(day_difference)
      end

      delta = possible_delta.min
      next_date_obj = (arrival_date_obj + delta)
      next_date = next_date_obj.strftime('%Y-%m-%d')
      next_time = available_time
      next_day = WDAY_DAY_MAP[next_date_obj.wday]
      return {next_date: next_date, next_time: next_time, next_day: next_day}
    end
end
