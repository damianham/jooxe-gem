require 'spec_helper'

module Jooxe
  
  describe Model do
    before(:all) do
      $dbs = nil
      Jooxe::Loader.load_databases 'test/db/default*.yml'
    end
    
    before(:each) do
      @router = Router.new 
      @env = Hash.new
    end
    
    it "should return the ID for to_param" do
      model = User.new(:id => 17)
      model.to_param.should eq("17")
    end
    
    it "should return a list of users" do
      users = User.list
      users.size.should be > 3
    end
    
    it "should return a page of users" do
      users = User.list :page => 0,:rows => 2
      users.size.should eq(2)
    end
    
    it "should get all users" do
      users = User.all
      users.size.should be > 3
    end
  
    
    it "should create a new user" do
    users = User.list
      user = User.create :account_name => 'jim',
  :title => 'Mr', 
  :given_name => 'john',
  :surname => 'ldfkjsld',
  :country => 'GB',
  :name => 'Mr John ldfkjsld',
  :mail => 'john@example.com',
  :updated_at => '2012-12-21 23:59:59',
  :updated_by => 'admin' 

      user.id.should eq(users.size() + 1)
      user.given_name.should eq('john')
    end
    
    it "should get a single user" do
      user = User.get :id => 4
      user.should be_an_instance_of(User)
      user.id.should eq(4)
    end

    it "should update a user" do
      users = User.list

      user = User.get :id => users.last.id
      user.should be_an_instance_of(User)
      user.id.should eq(users.last.id)
      
      newuser = user.update :given_name => 'Joseph'
      
      newuser.given_name.should eq('Joseph')
      newuser.updated_at.should_not eq(user.updated_at)
    end
    
    it "should delete a user" do
      users = User.list

      user = User.get :id => users.last.id
      user.should be_an_instance_of(User)

      user.delete
      newusers = User.list

      newusers.size.should eq(users.size() -1)
    end
    
    it "should generate json data for a single instance" do
      users = User.list
      user = users[0]
      
      user.to_json.should match( /"surname":"#{user.surname}"/ )
    end
    
    it "should generate json data for a collection" do
      users = User.list
      user = users[0]

      users.to_json.should match(/surname":"#{user.surname}/)
      
    end
    
    it "should get the table display fields" do
      fields = User.fields_for_context(:table)
      fields.size.should eq(3)
      fields.should include :account_name
    end
    
    it "should set and get the view display fields" do
      User.fields = {:view => [:title,:country,:mail,:surname]}
      fields = User.fields_for_context(:view)
      fields.size.should eq(4)
      fields.should include :mail
    end
    
    it "should get the view display fields when no context given" do
      User.fields = {:view => [:title,:country,:mail,:surname]}
      fields = User.fields_for_context
      fields.size.should eq(4)
      fields.should include :country
    end
    
    it "should get the table display fields for an instance" do
      User.fields = {:view => [:title,:country,:mail,:surname],:table => [:account_name,:given_name,:surname]}

      fields = User.new.fields_for_context(:table)

      fields.size.should eq(3)
      fields.should include :account_name
    end
    
    it "should set and get the view display fields for an instance" do
      User.fields = {:view => [:title,:country,:mail,:surname],:table => [:account_name,:given_name,:surname]}
      fields = User.new.fields_for_context(:view)
      fields.size.should eq(4)
      fields.should include :mail
    end
    
    it "should get the view display fields for an instance when no context given" do
      User.fields = {:view => [:title,:country,:mail,:surname],:table => [:account_name,:given_name,:surname]}
      fields = User.new.fields_for_context
      fields.size.should eq(4)
      fields.should include :country
    end
    
    it "should return a range as an array of tuples" do
      users = User.list
      range = User.range

      # remove all users without a value in name - they will not appear in the range
      users = users.map{|item| item.name.nil? ? nil : item}.compact
      
      range.size.should eq (users.size)
      range[0][0].should eq(users[0].id)
    end
    
    it "should return related records" do
      user = User.get :id => 1
      posts = Post.list
      
      posts = posts.map{|x| x.user_id == 1 ? x : nil}.compact
      
      related = user.related :relation => 'post'
      related.size.should eq(posts.size)
    end
    
    it "should return bridged records" do
      user = User.get :id => 1
      
      comments = user.bridged :relation => 'comment', :through => 'user_comment'
      
      comments.size.should eq(3)
      comments[0].post_id.should eq(1)
      comments[1].post_id.should eq(1)
      comments[2].post_id.should eq(2)
    end
  end
end
