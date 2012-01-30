class Api::V1::ElectionsController < Api::V1::ApplicationController

  #caches_action :show, :expires_in => 1.hour

  # GET /api/v1/elections/1
  def show
    @all_tags = (params[:tags] == 'all')
    @only_published_candidacies = not(params[:published] == 'all')
  end

  # GET /api/v1/elections/search
  def search
    @only_published_candidacies = false
    unless params[:published] == 'all'
      @elections = @elections.where(published: true)
      @only_published_candidacies = true
    end
    @elections = @elections.where(name: /#{params[:name]}/i).includes(:candidacies)
  end

  # POST /api/v1/elections
  def create
    @election.contributors << current_user

    if @election.save
      render 'api/v1/elections/show.rabl', status: :created
    else
      render text: {errors: @election.errors}.to_json, status: :unprocessable_entity, layout: 'api_v1'
    end
  end

  # PUT /api/v1/elections/1
  def update
    if @election.update_attributes params[:election]
      #expire_action action: "show", id: @election.id
      
      render 'api/v1/elections/show.rabl', status: :ok
    else
      render text: {errors: @election.errors}.to_json, status: :unprocessable_entity, layout: 'api_v1'
    end
  end

  # POST /api/v1/elections/1/addtag
  def addtag
    tag = Tag.find params[:tagId]
    if params[:parentTagId]
      parent_tag = Tag.find params[:parentTagId]
    end

    @election_tag = ElectionTag.new election: @election, tag: tag, parent_tag: parent_tag

    if @election_tag.save
      #expire_action action: "show", id: @election.id
      render 'api/v1/elections/show.rabl', status: :created
    else
      render text: {errors: @election_tag.errors}.to_json, status: :unprocessable_entity, layout: 'api_v1'
    end
  end

  # POST /api/v1/elections/1/addcandidacy
  def addcandidacy
    candidates = params[:candidateIds].split(',').collect {|id| Candidate.find(id) }
    @election.candidacies.build candidates: candidates

    if @election.save
      #expire_action action: "show", id: @election.id
      render 'api/v1/elections/show.rabl', status: :created
    else
      render text: {errors: @election.errors}.to_json, status: :unprocessable_entity, layout: 'api_v1'
    end
  end

  # DELETE /api/v1/elections/1/removetag
  def removetag
    @election.election_tags.where(tag_id: params[:tagId]).destroy_all
    #expire_action action: "show", id: @election.id
    head :ok
  end
  
end
