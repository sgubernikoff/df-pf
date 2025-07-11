class UsersController < ApplicationController
  rescue_from ActiveRecord::RecordInvalid, with: :render_unprocessable_entity
  rescue_from ActiveRecord::RecordNotFound, with: :render_not_found
    
  before_action :set_user, only: %i[show update destroy]

  # GET /users
  def index
    unless current_user.is_admin
      return render json: { error: "Unauthorized", user_id: current_user.id }, status: :unauthorized
    end

    page = params[:page].to_i > 0 ? params[:page].to_i : 1
    per_page = params[:per_page].to_i > 0 ? params[:per_page].to_i : 20

    @users = current_user.clients.order(created_at: :desc).page(page).per(per_page)

    render json: {
      users: UserSerializer.new(@users).serializable_hash,
      meta: {
        current_page: @users.current_page,
        total_pages: @users.total_pages,
        total_count: @users.total_count
      }
    }
  end

  # GET /users/search?:query
  def search
    query = params[:query].to_s.strip

    if query.blank?
      return render json: []
    end

    @users = current_user.clients.where("name ILIKE ? AND is_admin = ?", "%#{query}%", false).limit(10)

    render json: UserSerializer.new(@users).serializable_hash
  end

  # GET /users/1
  def show
    if current_user.is_admin
      @user = User.find_by(id: params[:id])
      return render_not_found unless @user
    end

    if @user.salesperson == current_user
      render json: UserSerializer.new(@user).serializable_hash
    else
      render json: { error: "Unauthorized", user_id: current_user.id }, status: :unauthorized
    end
  end

  def show_me
    render json: {
      status: { code: 200 },
      data: UserSerializer.new(current_user).serializable_hash[:data][:attributes]
    }
  end

  # POST /users
  def create
    unless current_user.is_admin
      return render json: { error: "Unauthorized", user_id: current_user.id }, status: :unauthorized
    end
    @user = User.new(user_params)

    
    if @user.save
      render json: @user, status: :created, location: @user
    else
      render json: {errors:@user.errors}, status: :unprocessable_entity
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
    @user = current_user
  end

  # Only allow a list of trusted parameters through.
  def user_params
    params.require(:user).permit(:name, :email, :password, :password_confirmation, :is_admin)
  end

  def render_unprocessable_entity(exception)
    render json: { errors: exception.record.errors }, status: :unprocessable_entity
  end

  def render_not_found
    render json: { error: "Not found" }, status: :not_found
  end
end