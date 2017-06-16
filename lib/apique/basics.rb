# Basic functional for API implementation.
module Apique::Basics
  extend ActiveSupport::Concern
  
  included do
    before_action :authorize_access
    
    if defined? CanCan
      rescue_from CanCan::AccessDenied do |e|
        render json: {error: e.message}, status: :forbidden
      end
    end
    
    rescue_from NotImplementedError do |e|
      render json: {error: e.message}, status: :not_acceptable
    end
  end
  
  
  private
  
  ### Authorization ###
  
  # @virtual
  # Used to immediately halt request processing before any other action would be done.
  # E.g. call `authorize! :access, :admin` inside an admin-only controller
  # or check a token in a secure public controller.
  def authorize_access
  end
  
  
  ### Basic getters-setters ###
  
  # @return [Ability]
  def current_ability
    @current_ability ||= Ability.new current_user
  end
  
  # The plural name of the ORM class.
  # @return [String]
  def collection_name
    @collection_name ||= params[:model] || controller_name.underscore.tr('/', '~')
  end

  # The ORM class of the resource.
  # @return [Class]
  def resource_class
    @resource_class ||= collection_name.singularize.tr('~', '/').classify.constantize
  end
  
end