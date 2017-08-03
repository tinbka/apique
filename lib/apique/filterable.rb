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
  
  UUID_RE = /^[a-f\d]{8}(-[a-f\d]{4}){3}-[a-f\d]{12}$/
  BOOL_RE = /^(true|false|t|f)$/
  ISO8601_RE = /^\d{4}(-\d\d){2}T\d\d(:\d\d){2}(\.\d+)?Z([+-]\d\d:\d\d)?$/
  
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
          conditions = k.split('_or_').map do |k|
            case get_cast_type(k)
            when :text
              if v.is_a? Array
                ["#{k} IN (?)", v.select(&:present?)]
              else
                ["#{k} ILIKE ?", "%#{v}%"]
              end
            when :integer
              if v.is_a? Hash
                [:from, :to].each {|x| v[x] &&= v[x].to_i}
                from_to_statement(k, v)
              elsif enum_map = resource_class.defined_enums[k.to_s]
                if v.is_a? Array
                  ["#{k} IN (?)", v.map {|vi| enum_map[vi]}]
                else
                  ["#{k} = ?", enum_map[v]]
                end
              else
                if v.is_a? Array
                  ["#{k} IN (?)", v.map(&:to_i)]
                else
                  ["#{k} = ?", v.to_i]
                end
              end
            when :uuid
              if v.is_a? Array
                ["#{k} IN (?)", v.select {|vi| v =~ UUID_RE}]
              else
                if v =~ UUID_RE
                  ["#{k} = ?", v]
                end
              end
            when :boolean
              if v =~ BOOL_RE
                ["#{k} = ?", v]
              end
            when :datetime
              [:from, :to].each {|x| v.delete x if v[x] !~ ISO8601_RE}
              from_to_statement(k, v)
            end
          end.compact
          
          if conditions.blank?
            collection = collection.none
            break
          end
          
          collection = collection.where conditions.map(&:first)*' OR ', *conditions.map(&:last)
        end
      end
      
      set_collection collection
    end
  end
  
  if ActiveRecord::VERSION::MAJOR >= 5
    def get_cast_type_class(field)
      resource_class.columns.find {|i| i.name == field}.instance_variable_get(:@cast_type).class
    end
  else
    def get_cast_type_class(field)
      resource_class.columns.find {|i| i.name == field}.cast_type
    end
  end
  
  if ActiveRecord::VERSION::MAJOR >= 5 and ActiveRecord::VERSION::MINOR >= 1
    def text_type_class?(type_class)
      type_class <= ActiveModel::Type::String
    end
  else
    def text_type_class?(type_class)
      [ActiveModel::Type::String, ActiveModel::Type::Text].find {|k| type_class <= k}
    end
  end
  
  def get_cast_type(field)
    type_class = get_cast_type_class(field)
    if text_type_class?(type_class)
      :text
    elsif type_class <= ActiveModel::Type::Integer
      :integer
    elsif type_class <= ActiveModel::Type::Boolean
      :boolean
    elsif type_class <= ActiveModel::Type::DateTime
      :datetime
    elsif type_class <= ActiveRecord::ConnectionAdapters::PostgreSQL::OID::Uuid
      :uuid
    end
  end
  
  def from_to_statement(k, v)
    if v[:from].present? and v[:to].present?
      ["#{k} BETWEEN ? AND ?", v[:from], v[:to]]
    elsif v[:from].present?
      ["#{k} >= ?", v[:from]]
    elsif v[:to].present?
      ["#{k} <= ?", v[:to]]
    end
  end
  
end