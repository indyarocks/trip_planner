class TrainSchedulesController < ApplicationController
  http_basic_authenticate_with name: "chandan", password: "secrettrip"
  before_action :set_train_schedule, only: [:show, :edit, :update, :destroy]

  # GET /train_schedules
  # GET /train_schedules.json
  def index
    @train_schedules = TrainSchedule.all
  end

  # GET /train_schedules/1
  # GET /train_schedules/1.json
  def show
  end

  # GET /train_schedules/new
  def new
    @train_schedule = TrainSchedule.new
  end

  # GET /train_schedules/1/edit
  def edit
  end

  # POST /train_schedules
  # POST /train_schedules.json
  def create
    @train_schedule = TrainSchedule.new(train_schedule_params)

    respond_to do |format|
      if @train_schedule.save
        format.html { redirect_to @train_schedule, notice: 'Train schedule was successfully created.' }
        format.json { render :show, status: :created, location: @train_schedule }
      else
        format.html { render :new }
        format.json { render json: @train_schedule.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /train_schedules/1
  # PATCH/PUT /train_schedules/1.json
  def update
    respond_to do |format|
      if @train_schedule.update(train_schedule_params)
        format.html { redirect_to @train_schedule, notice: 'Train schedule was successfully updated.' }
        format.json { render :show, status: :ok, location: @train_schedule }
      else
        format.html { render :edit }
        format.json { render json: @train_schedule.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /train_schedules/1
  # DELETE /train_schedules/1.json
  def destroy
    @train_schedule.destroy
    respond_to do |format|
      format.html { redirect_to train_schedules_url, notice: 'Train schedule was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_train_schedule
      @train_schedule = TrainSchedule.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def train_schedule_params
      params.require(:train_schedule).permit(:train_number, :station_code, :distance_from_origin, :arrival_time, :departure_time, :sun, :mon, :tue, :wed, :thu, :fri, :sat, :journey_day)
    end
end
