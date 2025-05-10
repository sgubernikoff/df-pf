require "base64"

class VisitsController < ApplicationController
    # GET /visits
    def index
      @visits = Visit.includes(:dresses).all
  
      respond_to do |format|
        format.html # renders index.html.erb if needed
        format.json { render json: @visits.to_json(include: :dresses) }
      end
    end
  
    # GET /visits/:id
    def show
      @visit = Visit.find(params[:id])
    
      if @visit.visit_pdf.attached?
        base64_pdf = Base64.strict_encode64(@visit.visit_pdf.download)
        puts base64_pdf
        render json: {
          pdf_base64: "data:application/pdf;base64,#{base64_pdf}"
        }
      else
        render json: { error: "PDF not available yet." }, status: :not_found
      end
    end
  
    # GET /visits/new
    def new
      @visit = Visit.new
    end
  
    # POST /visits
    def create
      @visit = Visit.new(visit_params)
  
      if @visit.save
        respond_to do |format|
          format.html { redirect_to @visit, notice: 'Visit was successfully created.' }
          format.json { render json: @visit, status: :created }
        end
      else
        respond_to do |format|
          format.html { render :new }
          format.json { render json: @visit.errors, status: :unprocessable_entity }
        end
      end
    end
  
    # GET /visits/:id/edit
    def edit
      @visit = Visit.find(params[:id])
    end
  
    # PATCH/PUT /visits/:id
    def update
      @visit = Visit.find(params[:id])
  
      if @visit.update(visit_params)
        respond_to do |format|
          format.html { redirect_to @visit, notice: 'Visit was successfully updated.' }
          format.json { render json: @visit }
        end
      else
        respond_to do |format|
          format.html { render :edit }
          format.json { render json: @visit.errors, status: :unprocessable_entity }
        end
      end
    end
  
    # DELETE /visits/:id
    def destroy
      @visit = Visit.find(params[:id])
      @visit.destroy
  
      respond_to do |format|
        format.html { redirect_to visits_url, notice: 'Visit was successfully destroyed.' }
        format.json { head :no_content }
      end
    end
  
    private
  
    def visit_params
      params.require(:visit).permit(
        :customer_name,
        :customer_email,
        :notes,
        dress_ids: [],
        images: []
      )
    end
  end
  