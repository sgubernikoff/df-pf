class DressesController < ApplicationController
    # This action will display all the dresses
    def index
      @dresses = Dress.all
    end
  
    # This action will show a specific dress by its ID
    def show
      @dress = Dress.find(params[:id])
    end
  
    # This action will render the form to create a new dress
    def new
      @dress = Dress.new
    end
  
    # This action will create a new dress
    def create
      @dress = Dress.new(dress_params)
  
      if @dress.save
        redirect_to @dress, notice: 'Dress was successfully created.'
      else
        render :new
      end
    end
  
    # This action will render the form to edit an existing dress
    def edit
      @dress = Dress.find(params[:id])
    end
  
    # This action will update the dress's information
    def update
      @dress = Dress.find(params[:id])
  
      if @dress.update(dress_params)
        redirect_to @dress, notice: 'Dress was successfully updated.'
      else
        render :edit
      end
    end
  
    # This action will delete the dress
    def destroy
      @dress = Dress.find(params[:id])
      @dress.destroy
      redirect_to dresses_url, notice: 'Dress was successfully destroyed.'
    end
  
    private
  
    # Strong parameters to allow specific fields for Dress
    def dress_params
      params.require(:dress).permit(:name, :description, :price, :images)
    end
  end
