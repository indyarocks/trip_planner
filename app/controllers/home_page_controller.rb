class HomePageController < ApplicationController

  def home

  end

  # Action to render the trip search_result field partial on home page
  def get_trip_type
    @stations = Station.get_stations
    params[:trip_type] = TrainSchedule::VALID_TRIP_TYPES.include?(params[:trip_type]) ? params[:trip_type] : 'one_way'
    locals = params.merge(stations: @stations)
    html = render_to_string partial: "home_page/home/#{params[:trip_type]}_trip", locals: locals, layout: false
    render json: {:success => true, :html => html}
  end


  def search_trip
    @result = TrainSchedule.find_suitable_trip_schedule(params)
  end

end
