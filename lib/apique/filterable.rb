# Basic functional to perform detailed filtering inside record collections.
module Apique::Filterable
  extend ActiveSupport::Concern
  include Apique::Listable
  
  included do
    params_usage['q'] = {
      desc: "q [String] filter by a value of a default field (optional)",
      example: "q=abc requests to filter a default column(s) by abc substring"
    }
    params_usage['q[]'] = {
      desc: "q [Object] filter by a value of a field specified as object key (optional, overrides plain `q')",
      example: "q[amount]=123&q[title_or_description]=abc requests to filter by amount equal to 123 AND (title OR description contains abc substring)"
    }
    params_types['q'] = [String, Hash]
  end
  
  
  private
  
  ### Basic getters-setters ###
  
  # @abstract
  # Filter by this column implicitly when q=value is passed. Supports field_or_field2 notation.
  # @return [String]
  def default_filter_column
    raise NotImplementedError, "A developer must implement default_filter_column for this controller to allow plain `q' query parameter."
  end
  
  
  ### Whitelists ###
  
  # @virtual
  # Pattern method for params a user can filter by. Add whitelisting logic in a descendant using `super`.
  # @return [ActionController::Parameters]
  def filter_params
    params[:q].presence || ActionController::Parameters.new
  end
  
  
  ### Collection filters ###
  
  # Filter the current collection with {column_or_scope => value, ... } Hash within params[:q]
  # @return [DB collection proxy]
  def filter_collection!
    if params[:q].is_a? String
      params[:q] = {default_filter_column => params[:q]}
      return filter_collection!
    end
    
    if filter_params.present?
      collection = get_collection
        
      filter_params.each do |k, v|
        next if v.blank?
          
        if resource_class.respond_to? "search_by_#{k}"
          # A call to a scope. A method must be defined as a scope to work on another ORM relation.
          collection = collection.public_send "search_by_#{k}", v
        else
          is_text = [ActiveRecord::Type::String, ActiveRecord::Type::Text].include? resource_class.columns.find {|i| i.name == k}.cast_type
          
          if k =~ /_or_/
            fields = k.split('_or_')
            
            if is_text
              collection = collection.where [
                fields.map {|i| "#{i} ILIKE ?"} * ' OR ',
                *(["%#{v}%"] * fields.size)
              ]
            else
              collection = collection.where [
                fields.map {|i| "#{i} = ?"} * ' OR ',
                *([v] * fields.size)
              ]
            end
          else
            if is_text
              collection = collection.where ["#{k} ILIKE ?", "%#{v}%"]
            else
              collection = collection.where k => v
            end
          end
        end
      end
      
      set_collection collection
    end
  end
  
end