require 'test_helper'

class TrainSchedulesControllerTest < ActionController::TestCase
  setup do
    @train_schedule = train_schedules(:one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:train_schedules)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create train_schedule" do
    assert_difference('TrainSchedule.count') do
      post :create, train_schedule: { arrival_time: @train_schedule.arrival_time, departure_time: @train_schedule.departure_time, distance_from_origin: @train_schedule.distance_from_origin, fri: @train_schedule.fri, journey_day: @train_schedule.journey_day, mon: @train_schedule.mon, sat: @train_schedule.sat, station_code: @train_schedule.station_code, sun: @train_schedule.sun, thu: @train_schedule.thu, train_number: @train_schedule.train_number, tue: @train_schedule.tue, wed: @train_schedule.wed }
    end

    assert_redirected_to train_schedule_path(assigns(:train_schedule))
  end

  test "should show train_schedule" do
    get :show, id: @train_schedule
    assert_response :success
  end

  test "should get edit" do
    get :edit, id: @train_schedule
    assert_response :success
  end

  test "should update train_schedule" do
    patch :update, id: @train_schedule, train_schedule: { arrival_time: @train_schedule.arrival_time, departure_time: @train_schedule.departure_time, distance_from_origin: @train_schedule.distance_from_origin, fri: @train_schedule.fri, journey_day: @train_schedule.journey_day, mon: @train_schedule.mon, sat: @train_schedule.sat, station_code: @train_schedule.station_code, sun: @train_schedule.sun, thu: @train_schedule.thu, train_number: @train_schedule.train_number, tue: @train_schedule.tue, wed: @train_schedule.wed }
    assert_redirected_to train_schedule_path(assigns(:train_schedule))
  end

  test "should destroy train_schedule" do
    assert_difference('TrainSchedule.count', -1) do
      delete :destroy, id: @train_schedule
    end

    assert_redirected_to train_schedules_path
  end
end
