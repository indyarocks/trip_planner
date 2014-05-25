class Train < ActiveRecord::Base
  validates :number, presence: true, uniqueness: true

  def self.valid_train_numbers
    all.collect{|train| train.number}
  end
end
