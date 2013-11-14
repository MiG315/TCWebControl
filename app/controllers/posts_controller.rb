class PostsController < ApplicationController
def new
end

def create
  #render :text => params[:post].inspect
  @post = Post.new(params[:post])
  
  @post.save
  redirect_to :action => :show, :id => @post.id
end

def show
  @post = Post.find(params[:id])
end

def index
  @posts = Post.all
end

end