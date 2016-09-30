require_relative '01_sql_object.rb'

class Cat < SQLObject
  belongs_to :human, foreign_key: :owner_id
  has_one_through :home, :human, :house

  finalize!
end

class Human < SQLObject
  validates :fname, nil?: false
  validates :lname, nil?: false
  self.table_name = 'humans'

  has_many :cats, foreign_key: :owner_id
  belongs_to :house

  finalize!
end

class House < SQLObject
  has_many :humans
  validate :valid_address

  def valid_address
    if self.address.nil?
      self.errors[:address] << "Can't be absent"
    end
    unless self.address.match(/\d+ .+ Drive/)
      self.errors[:address] << "needs to be a valid address"
    end
  end

  finalize!
end
