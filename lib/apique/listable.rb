# Basic functional for retrieving collections of records.
module Apique::Listable
  extend ActiveSupport::Concern
  include Apique::Basics
  
  included do
    # [Hash: param_key_string => {:desc, :example}]
    class_attribute :params_usage
    self.params_usage = {}
    params_usage['f'] = {
      desc: "f [String] serialize the collection in a specific format (optional)"
    }
    params_usage['j'] = {
      desc: "j [Array<String>] join a set of relations (optional)"
    }
    # [Hash: param_key_string => param_types_array]
    class_attribute :params_types
    self.params_types = {}
    params_types['f'] = [String]
    params_types['j'] = [Array]
    
    helper_method :subject_collection
  
    before_action :validate_query, only: :index
    
    rescue_from Apique::MalformedParameters do |e|
      render json: e, status: :bad_request
    end
  end
  
  
  # Exception will raise if a request query would contain an incorrect of malformed parameter.
  # This will provide the front-end with a description of the correct API usage.
  class ::Apique::MalformedParameters < Exception
    
    def initialize(request, param, params_usage, *args)
      message = "Bad request query: malformed parameter #{param}"
      usage = "GET #{request.fullpath[/[^?]+/]}?#{params_usage.keys*'&'}"
      
      @json = {message: message, usage: usage, params: params_usage.values}
      
      message = [
        message, "Usage: #{usage}",
        *params_usage.values.flat_map {|v| [v[:desc], "Example: #{v[:example]}"]}
      ]*"\n"
      
      super(message, *args)
    end
    
    def as_json(*)
      @json
    end
    
  end
  
  
  # GET /api/{plural_resource_name}
  def index
    join_relations!
    if respond_to? :filter_collection!, true
      filter_collection!
    end
    if respond_to? :sort_collection!, true
      sort_collection!
    end
    if respond_to? :paginate_collection!, true
      paginate_collection!
    end
    render json: subject_collection, apique_format: params[:f] || 'default'
  end
  
  
  private
  
  ### Basic getters-setters ###
  
  # The name of ivar to cache the filtered collection.
  # @return [String]
  def collection_variable_name
    @collection_variable_name ||= "@#{collection_name.tr('~', '_')}"
  end

  # Returns the collection from the created instance variable.
  # @return [DB collection proxy]
  def get_collection
    instance_variable_get(collection_variable_name) || set_collection
  end
  
  # Used as a helper to create DRYed json builders in inheritable controllers.
  alias_method :subject_collection, :get_collection

  # Puts the collection into an instance variable.
  # In most cases, the collection exactly allowed for the user by CanCan rules should be an entry point.
  # @return [DB collection proxy]
  def set_collection(collection = defined?(CanCan) ? resource_class.accessible_by(current_ability) : resource_class.all)
    instance_variable_set(collection_variable_name, collection)
  end
  
  
  ### Whitelists ###
  
  # @virtual
  # Pattern method for relations a user can join. Add whitelisting logic in a descendant using `super`.
  # @return [ActionController::Parameters]
  def join_params
    params[:j].presence || ActionController::Parameters.new
  end
  
  # Check consistency of a query parameters for a list. Use it as a before filter if needed.
  # @raise [MalformedParameters] if the request query is malformed.
  def validate_query
    request.query_parameters.each do |k, v|
      param_is_valid = self.class.params_types.find do |name, types|
        if k == name
          break true if types.any? {|type| v.is_a? type}
          raise MalformedParameters.new(request, k, self.class.params_usage)
        end
      end
      unless param_is_valid
        raise MalformedParameters.new(request, k, self.class.params_usage)
      end
    end
  end
  
  
  ### Collection filters ###
  
  # Join (eager load) to the current collection the references specified by params[:j]
  # @return [DB collection proxy]
  def join_relations!
    collection = get_collection
    
    if join_params.present?
      collection = collection.includes(*join_params)
    end
    
    set_collection collection
  end
  
end