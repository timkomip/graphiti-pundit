class Person
  attr_accessor :id, :name

  def initialize(id, name)
    @id = id
    @name = name
  end

  DATA = [Person.new(1, "Mike"), Person.new(2, "Bob")]

  def self.all
    DATA
  end
end
