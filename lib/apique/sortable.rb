# Basic functional for ordering record collections.
module Apique::Sortable
  extend ActiveSupport::Concern
  include Apique::Listable
  
  included do
    params_usage['s'] = {
      desc: "s [Object] sort by a field in a specified direction (optional)",
      example: "s[id]=1&s[name]=-1&s[price] requests to sort by by id (most recent last), name (Z to A), and price (lower to higher)"
    }
    params_types['s'] = [Hash]
  end
  
  
  private
  
  ### Whitelists ###
  
  # @virtual
  # Pattern method for params a user can sort by. Add whitelisting logic in a descendant using `super`.
  # @return [ActionController::Parameters]
  def sort_params
    params[:s].presence || ActionController::Parameters.new
  end
  
  
  ### Collection filters ###
  
  # Sort the current collection by {column => direction, ... } Hash within params[:s]
  # @return [DB collection proxy]
  def sort_collection!
    collection = get_collection
    
    if sort_params.present?
      sort_params.each do |k, v|
        if v.present? and ['desc', '-1'].include? v.downcase
          collection = collection.order "#{k} desc"
        else
          collection = collection.order "#{k} asc"
        end
      end
    end
    if collection.order_values.blank?
      collection = collection.order "id desc"
    end
    
    set_collection collection
  end
  
end