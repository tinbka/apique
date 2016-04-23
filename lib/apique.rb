require "apique/version"

module Apique
  extend ActiveSupport::Autoload
  
  autoload :Basics
  autoload :Editable
  autoload :Filterable
  autoload :Listable
  autoload :Paginatable
  autoload :Pickable
  autoload :Searchable
  autoload :Sortable
end
