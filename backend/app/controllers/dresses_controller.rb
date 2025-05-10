class DressesController < ApplicationController
  # before_action :set_dress, only: [:show, :edit, :update, :destroy]

  # GET /dresses
  def index
    @dresses = Dress.all

    render json: @dresses
  end

  # GET /dresses/:id
  def show
    respond_to do |format|
      format.html
      format.json { render json: @dress }
    end
  end

  # GET /dresses/new
  def new
    @dress = Dress.new
  end

  # POST /dresses
  def create
    @dress = Dress.new(dress_params)

    if @dress.save
      respond_to do |format|
        format.html { redirect_to @dress, notice: 'Dress was successfully created.' }
        format.json { render json: @dress, status: :created }
      end
    else
      respond_to do |format|
        format.html { render :new }
        format.json { render json: @dress.errors, status: :unprocessable_entity }
      end
    end
  end

  # GET /dresses/:id/edit
  def edit
  end

  # PATCH/PUT /dresses/:id
  def update
    if @dress.update(dress_params)
      respond_to do |format|
        format.html { redirect_to @dress, notice: 'Dress was successfully updated.' }
        format.json { render json: @dress }
      end
    else
      respond_to do |format|
        format.html { render :edit }
        format.json { render json: @dress.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /dresses/:id
  def destroy
    @dress.destroy
    respond_to do |format|
      format.html { redirect_to dresses_url, notice: 'Dress was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private

  def set_dress
    @dress = Dress.find(params[:id])
  end

  def dress_params
    params.require(:dress).permit(:name, :description, :price, images: [])
  end
end
