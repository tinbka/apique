# Just a shortcut for inclusion.
module Apique::Searchable
  extend ActiveSupport::Concern
  include Apique::Filterable
  include Apique::Sortable
  include Apique::Paginatable
end