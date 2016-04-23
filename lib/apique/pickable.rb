# Basic functional for retrieving discrete records.
module Apique::Pickable
  extend ActiveSupport::Concern
  include Apique::Basics
  
  included do
    helper_method :subject_resource
  
    rescue_from ActiveRecord::RecordNotFound, Apique::RecordNotFound do |e|
      render json: {error: e.message}, status: :not_found
    end
  end
  
  # This exception will be raised if a request would query for an inexisted record and
  # this case would not have been handled by CanCan.
  class Apique::RecordNotFound < ActionController::RoutingError; end
  
  
  # GET /api/{plural_resource_name}/{id}
  def show
    render json: subject_resource
  end
  
  
  private
  
  ### Basic getters-setters ###

  # The singular name of the ORM class.
  # @return [String]
  def resource_name
    @resource_name ||= collection_name.singularize
  end

  # Returns the resource from the created instance variable.
  # @return [Object]
  def get_resource
    instance_variable_get("@#{resource_name}") || set_resource
  end
  
  # Used as a helper to create DRYed json builders in inheritable controllers.
  alias_method :subject_resource, :get_resource

  # Puts the resource into an instance variable.
  # @raise [ActionController::RoutingError] if there is no resource found.
  # @return [Object]
  def set_resource(resource = nil)
    resource ||= resource_class.find(params[:id])
    unless resource
      raise RecordNotFound, "could not find a record of type #{resource_class} with id = #{params[:id]}"
    end
    
    instance_variable_set("@#{resource_name}", resource)
  end
  
end