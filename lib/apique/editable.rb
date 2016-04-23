# Basic functional for creating, updating, and destroying records.
module Apique::Editable
  extend ActiveSupport::Concern
  include Apique::Pickable
  
  included do
    rescue_from ActionController::ParameterMissing do |e|
      render json: {error: e.message}, status: :bad_request
    end
    
    rescue_from ActionController::UnpermittedParameters, ActiveModel::ForbiddenAttributesError do |e|
      render json: {error: e.message}, status: :unprocessable_entity
    end  
  end
  
  
  # A resource is already built by CanCan according to load_resource params in the current controller.
  # POST /api/{plural_resource_name}
  def create
    if get_resource.save
      render :show, status: :created
    else
      render json: {errors: get_resource.errors}
    end
  end

  # PATCH/PUT /api/{plural_resource_name}/{id}
  def update
    if get_resource.update(update_api_params)
      render :show
    else
      render json: {errors: get_resource.errors}
    end
  end

  # DELETE /api/{plural_resource_name}/{id}
  def destroy
    get_resource.destroy
    unless get_resource.errors.present?
      on_destroy
    else
      render json: {errors: get_resource.errors}
    end
  end
  
  
  private
  
  ### Default callbacks ###
  
  def on_destroy
    head :no_content
  end
  
  
  ### Basic getters-setters ###
  
  # Only allow a trusted parameter "white list" through.
  # If a single resource is loaded for #create or #update,
  # then the controller for the resource must implement
  # the method "update_params" to limit permitted
  # parameters for the individual model.
  def update_api_params
    @resource_params ||= self.send('update_params')
  end
  
end