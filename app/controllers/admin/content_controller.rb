require 'base64'

module Admin; end

class Admin::ContentController < Admin::BaseController
  layout "administration", except: [:show, :autosave]

  cache_sweeper :blog_sweeper

  def auto_complete_for_article_keywords
    @items = Tag.find_with_char params[:article][:keywords].strip
    render inline: "<%= raw auto_complete_result @items, 'name' %>"
  end

  def index
    @search = params[:search] ? params[:search] : {}

    @articles = Article.search_with_pagination(@search, {page: params[:page], per_page: this_blog.admin_display_elements})

    if request.xhr?
      render partial: 'article_list', locals: { articles: @articles }
    else
      @article = Article.new(params[:article])
    end
  end

  def new
    new_or_edit
  end

  def edit
    @article = Article.find(params[:id])
    unless @article.access_by? current_user
      redirect_to action: 'index'
      flash[:error] = _("Error, you are not allowed to perform this action")
      return
    end
    new_or_edit
  end

  def destroy
    @record = Article.find(params[:id])

    unless @record.access_by?(current_user)
      flash[:error] = _("Error, you are not allowed to perform this action")
      return(redirect_to :action => 'index')
    end

    return(render 'admin/shared/destroy') unless request.post?

    @record.destroy
    flash[:notice] = _("This article was deleted successfully")
    redirect_to :action => 'index'
  end

  def resource_do(action)
    @article = Article.find(params[:id])
    @resources = Resource.by_created_at
    @resource = Resource.find(params["resource_id"])
    @article.resources.send(action, resource)
    @article.save

    render :partial => "show_resources"
  end

  def resource_add
    resource_do(:<<)
  end

  def resource_remove
    resource_do(:delete)
  end

  def attachment_box_add
    render :update do |page|
      page["attachment_add_#{params[:id]}"].remove
      page.insert_html :bottom, 'attachments',
          :partial => 'admin/content/attachment',
          :locals => { :attachment_num => params[:id], :hidden => true }
      page.visual_effect(:toggle_appear, "attachment_#{params[:id]}")
    end
  end

  def autosave
    id = params[:id]
    id = params[:article][:id] if params[:article] && params[:article][:id]

    @article = Article.get_or_build_article(id)
    @article.text_filter = current_user.text_filter if current_user.simple_editor?

    get_fresh_or_existing_draft_for_article

    @article.attributes = params[:article]

    # Crappy workaround to have the visual editor work.
    if current_user.visual_editor?
      @article.body = params[:article][:body_and_extended]
    end

    @article.published = false
    @article.set_author(current_user)
    @article.save_attachments!(params[:attachments])
    @article.state = "draft" unless @article.state == "withdrawn"

    if @article.title.blank?
      lastid = Article.find(:first, :order => 'id DESC').id
      @article.title = "Draft article " + lastid.to_s
    end

    if @article.save
      render(:update) do |page|
        page.replace_html('autosave', hidden_field_tag('article[id]', @article.id))
        page.replace_html('preview_link', link_to(_("Preview"), {:controller => '/articles', :action => 'preview', :id => @article.id}, {:target => 'new', :class => 'btn info'}))
        page.replace_html('destroy_link', link_to_destroy_draft(@article))
        if params[:article][:published_at] and params[:article][:published_at].to_time.to_i < Time.now.to_time.to_i
          page.replace_html('publish', calendar_date_select('article', 'published_at', {:class => 'span7'})) if @article.state.to_s.downcase == "draft"
        end
      end

      return true
    end
    render :text => nil
  end

  protected

  def get_fresh_or_existing_draft_for_article
    if @article.published and @article.id
      parent_id = @article.id
      @article = Article.drafts.child_of(parent_id).first || Article.new
      @article.allow_comments = this_blog.default_allow_comments
      @article.allow_pings    = this_blog.default_allow_pings
      @article.parent_id      = parent_id
    end
  end

  attr_accessor :resources, :categories, :resource, :category

  def new_or_edit
    id = params[:id]
    id = params[:article][:id] if params[:article] && params[:article][:id]
    @article = Article.get_or_build_article(id)
    @article.text_filter = current_user.text_filter if current_user.simple_editor?

    @post_types = PostType.find(:all)
    if request.post?
      if params[:article][:draft]
        get_fresh_or_existing_draft_for_article
      else
        if not @article.parent_id.nil?
          @article = Article.find(@article.parent_id)
        end
      end
    end

    @article.keywords = Tag.collection_to_string @article.tags
    @article.attributes = params[:article]
    # TODO: Consider refactoring, because double rescue looks... weird.

    @article.published_at = DateTime.strptime(params[:article][:published_at], "%B %e, %Y %I:%M %p GMT%z").utc rescue Time.parse(params[:article][:published_at]).utc rescue nil

    if request.post?
      @article.set_author(current_user)

      @article.save_attachments!(params[:attachments])
      @article.state = "draft" if @article.draft

      if @article.save
        unless @article.draft
          Article.where(parent_id: @article.id).map(&:destroy)
        end
        @article.categorizations.clear
        if params[:categories]
          Category.find(params[:categories]).each do |cat|
            @article.categories << cat
          end
        end
        set_the_flash
        redirect_to :action => 'index'
        return
      end
    end

    @images = Resource.images_by_created_at.page(params[:page]).per(10)
    @resources = Resource.without_images_by_filename
    @macros = TextFilter.macro_filters
    render 'new'
  end

  def set_the_flash
    case params[:action]
    when 'new'
      flash[:notice] = _('Article was successfully created')
    when 'edit'
      flash[:notice] = _('Article was successfully updated.')
    else
      raise "I don't know how to tidy up action: #{params[:action]}"
    end
  end

end
