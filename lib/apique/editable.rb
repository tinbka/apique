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
      render json: get_resource, status: :created
    else
      render json: {errors: get_resource.errors}
    end
  end

  # PATCH/PUT /api/{plural_resource_name}/{id}
  def update
    if get_resource.update(apique_update_params)
      render json: get_resource
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
  
  # Puts the resource into an instance variable.
  # @raise [Apique::RecordNotFound] if there is no resource found.
  # @return [Object]
  def set_resource(resource = nil)
    resource ||= params[:id] ? resource_class.find(params[:id]) : resource_class.new(apique_create_params)
    unless resource
      raise Apique::RecordNotFound, "could not find a record of type #{resource_class} with id = #{params[:id]}"
    end
    
    instance_variable_set(resource_variable_name, resource)
  end
  
  # @virtual
  # Filters incoming params for <model>.create statements.
  def create_params
  end
  
  # @virtual
  # Filters incoming params for <record>.update statements.
  # Works also for <model>.create statements IF #create_params is not defined on a subclass.
  # It is very recommended to redefine it unless you're sure no one would attack your API with mass-assignment.
  def update_params
    params[resource_name.tr('~', '_')].to_unsafe_h
  end
  
  # Only allow a trusted parameter "white list" through.
  # If a single resource is loaded for #create or #update,
  # then the controller for the resource must implement
  # the method "update_params" to limit permitted
  # parameters for the individual model.
  def apique_update_params
    @resource_params ||= update_params
  end
  
  def apique_create_params
    @resource_params ||= create_params || update_params
  end
  
end