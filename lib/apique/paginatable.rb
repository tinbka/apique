# Basic functional for paginating record collections.
module Apique::Paginatable
  extend ActiveSupport::Concern
  include Apique::Listable
  
  included do
    class_attribute :per_page
    
    params_usage['page'] = {
      desc: "",
      example: "page=20"
    }
    params_types['page'] = [String]
    
    set_per_page 25
  end
  
  module ClassMethods
    
    def set_per_page(number)
      self.per_page = number
      params_usage['page'][:desc] = "page [Integer] 1-based number of a bunch of #{number} items list (optional)"
    end
    
  end
  
  
  private
  
  ### Collection filters ###
  
  # Get 1-based params[:page]-th page of the current collection.
  # @return [DB collection proxy]
  def paginate_collection!
    set_collection get_collection.page(params[:page]).per(self.class.per_page)
  end
  
end