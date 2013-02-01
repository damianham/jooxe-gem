class User < Jooxe::Model
  
  def initialize(*args)
    
    User.fields = {:table => [:account_name,:given_name,:surname]}
    super(*args)
  end
  
  
end