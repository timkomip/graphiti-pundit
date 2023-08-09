class ApplicationResource < Graphiti::Resource
  self.adapter = Graphiti::Adapters::Null

  def current_user
    context.current_user
  end

  def base_scope
    {}
  end
end

class PersonResource < ApplicationResource
  include Graphiti::Pundit::Authorization

  self.model = Person

  authorize_resource

  def resolve(scope)
    Person.all
  end
end
