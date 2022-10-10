class PostsController < ApplicationController
  before_action :set_post, only: %i[ show edit update destroy ]

  def index
    @posts = Post.all
    respond_to do |format|
      format.html
      format.pdf do
        render pdf: "Posts: #{@posts.count}", template: "posts/index", formats: [:html], layout: "pdf", disposition: :attachment
      end
    end
  end
  
  def show
    respond_to do |format|
      format.html
      format.pdf do
       render pdf: "Post id: #{@post.id}", template: "posts/doc", formats: [:html], layout: "pdf", disposition: :attachment
      end
    end
  end

  def new
    @post = Post.new post_params
  end

  def edit
    @quantites = [1, 2]
  end

  def create
    @post = Post.new(post_params)

    respond_to do |format|
      if @post.save
        format.html { redirect_to post_url(@post), notice: "Post was successfully created." }
        format.json { render :show, status: :created, location: @post }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @post.errors, status: :unprocessable_entity }
      end
    end
  end

  def update
    respond_to do |format|
      if @post.update(post_params)
        format.html { redirect_to post_url(@post), notice: "Post was successfully updated." }
        format.json { render :show, status: :ok, location: @post }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @post.errors, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    @post.destroy

    respond_to do |format|
      format.html { redirect_to posts_url, notice: "Post was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  private
     def set_post
      @post = Post.find(params[:id])
    end

    def post_params
      params.fetch(:post, {}).permit(:name, :title, :content, :quantite)
    end
end
