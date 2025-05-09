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
    # def show
    #   @visit = Visit.find(params[:id])
  
    #   respond_to do |format|
    #     format.html
    #     format.json { render json: @visit.to_json(include: :dresses) }
    #   end
    # end
    # def show
    #   @visit = Visit.find(params[:id])
  
    #   # Check if the visit PDF exists and encode it as base64
    #   if @visit.visit_pdf.attached?
    #     pdf_data = @visit.visit_pdf.download
    #     base64_pdf = Base64.encode64(pdf_data)
  
    #     render json: { pdf: base64_pdf }
    #   else
    #     render :show
    #   end
    # end
    def show
      @visit = Visit.find(params[:id])
    
      # Check if the visit PDF exists
      if @visit.visit_pdf.attached?
        # Set the appropriate headers to trigger the download
        send_data @visit.visit_pdf.download, 
                  filename: "visit_#{params[:id]}.pdf", 
                  type: "application/pdf", 
                  disposition: 'attachment'
      else
        render :show
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
        images: [] # <-- allow multiple file uploads
      )
    end
  end
  