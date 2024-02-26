class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  
  after_initialize :set_default_role, :if => :new_record?

  def set_default_role
    self.role ||= :user
  end
       
  def user?
    role == 'user'
  end
      
  def admin?
    role == 'admin'
  end

  def vendeur?
    role == 'vendeur'
  end

end
