class UsersController < ApplicationController
  rescue_from ActiveRecord::RecordInvalid,with: :render_unprocessable_entity
  rescue_from ActiveRecord::RecordNotFound,with: :render_not_found
    
  before_action :set_user, only: %i[ show update destroy ]

  # GET /users
  def index
    @users = User.all

    render json: UserSerializer.new(@users).serializable_hash
  end

  # GET /users/search?:query
  def search
    query = params[:query].to_s.strip

    if query.blank?
      return render json: []
    end

    @users = User.where("name ILIKE ?", "%#{query}%").limit(10)

    render json: UserSerializer.new(@users).serializable_hash
  end


  # GET /users/1
  def show
    render json: UserSerializer.new(@user).serializable_hash
  end

  def show_me
    render json: {
      status: { code: 200 },
      data: UserSerializer.new(current_user).serializable_hash[:data][:attributes]
    }
  end

  # POST /users
  def create
    @user = User.new(user_params)

    if @user.save
      render json: @user, status: :created, location: @user
    else
      render json: @user.errors, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /users/1
  def update
    if @user.update(user_params)
      render json: @user
    else
      render json: @user.errors, status: :unprocessable_entity
    end
  end

  # DELETE /users/1
  def destroy
    @user.destroy!
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_user
      @user = User.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def user_params
      params.require(:user).permit(:name, :email, :password, :password_confirmation)
    end
end
