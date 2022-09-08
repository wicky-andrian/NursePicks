# frozen_string_literal: true

class PostsController < ApplicationController
  before_action :set_post, only: %i[show destroy]
  before_action :signin_required, only: %i[create destroy]

  def index
    @post = Post.new
    @posts = Post.all
  end

  def show
    @comment = Comment.new
    @comments = @post.comments.includes(:user)
  end

  def create
    @post = current_user.posts.create(post_params)

    begin
      page = MetaInspector.new(@post.url)
      @post.title = page.title
      @post.image_url = page.meta['og:image'] || 'logo_picks.png'
      @post.site_name = page.meta['og:site_name']
    rescue StandardError
      flash.now[:alert] = 'この記事(URL)の投稿はできませんでした'
      render :index
      return
    end

    if @post.save
      @post.twitter_bot
      redirect_to @post, notice: "「#{@post.title}」を登録しました"
    else
      flash.now[:alert] = "記事投稿に失敗しました。#{@post.errors.full_messages[0]}。"
      render :index
    end
  end

  def destroy
    @post.destroy
    redirect_to root_path, notice: "「#{@post.title}」を削除しました"
  end

  private

  def set_post
    @post = Post.find(params[:id])
  end

  def post_params
    params.require(:post).permit(:url)
  end

  def signin_required
    return if current_user

    redirect_to root_path
    flash[:alert] = '記事投稿をするにはログインが必要です'
  end
end
