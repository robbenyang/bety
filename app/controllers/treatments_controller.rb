require 'will_paginate/array'

class TreatmentsController < ApplicationController
  before_filter :login_required, :except => [ :show ]

  require 'csv'

  def new_management
    @management = Management.new 

    respond_to do |format|
      format.js
    end
  end

  def create_new_management

    @treatment = Treatment.find(params[:management].delete(:id))

    @management = Management.new(params[:management])

    render :update do |page|
      if @management.save
        @treatment.managements << @management
        flash[:notice] = "Management was successfully created"
        page.replace_html 'edit_managements_treatments', :partial => 'edit_managements_treatments'
        page.replace_html 'new_management', :partial => 'new_management'
        page.call 'showHide', 'new_management'
      else
        flash[:notice] = "Management was not created"
        page.replace_html 'edit_managements_treatments', :partial => 'edit_managements_treatments'
        page.replace_html 'new_management', :partial => 'new_management'
      end
    end
   end

  def rem_managements_treatments
    @treatment = Treatment.find(params[:id])
    @management = Management.find(params[:management])

    render :update do |page|
      if @management.treatments.delete(@treatment)
        page.replace_html 'edit_managements_treatments', :partial => 'edit_managements_treatments'
      else
        page.replace_html 'edit_managements_treatments', :partial => 'edit_managements_treatments'
      end
    end
  end

  def edit_managements_treatments

    @treatment = Treatment.find(params[:id])

    render :update do |page|
      if !params[:management].nil?
        params[:management][:id].each do |c|
          @treatment.managements << Management.find(c)
        end
        page.replace_html 'edit_managements_treatments', :partial => 'edit_managements_treatments'
      else
        page.replace_html 'edit_managements_treatments', :partial => 'edit_managements_treatments'
      end
    end
  end

  def flag_control
    @treatment = Treatment.find(params[:id])

    if @treatment.control
      @treatment.control = 0
    else
      @treatment.control = 1
    end

    respond_to do |format|
      if @treatment.save
        flash[:notice] = 'Treatment was successfully updated.'
        format.html { redirect_to :back }
        format.xml  { head :ok }
        format.csv  { head :ok }
        format.json  { head :ok }
      else
        format.html { redirect_to :back }
        format.xml  { render :xml => @treatment.errors, :status => :unprocessable_entity }
        format.csv  { render :csv => @treatment.errors, :status => :unprocessable_entity }
        format.json  { render :json => @treatment.errors, :status => :unprocessable_entity }
      end
    end
  end

  def linked
    @c = Citation.find(session["citation"])
    @t = Treatment.find(params[:id])

    if @c.treatments.exists?(@t.id)
      @c.treatments.delete(@t)
    else
      @c.treatments<<@t
    end

    redirect_to :action => "index"
  end


  # GET /treatments
  # GET /treatments.xml
  def index
    if params[:format].nil? or params[:format] == 'html'
      if !session["citation"].nil?
  
        # If they have selected a citation we want to find all the sites
        # associated with it, then find all the citations associated with
        # those sites, and finally find all the treatments associated with
        # those citations and list them.
  
        tts = []
        @treatments = Citation.find(session["citation"]).treatments
        treatment_ids = @treatments.collect {|x| x.id}

        if !params[:unlinked].blank?
          tts = Treatment.includes({:citations => {:sites => :citations} }).where('(treatments.name like ? or treatments.definition like ?) and treatments.id not in (?)',
                                                                                  params[:treatment],
                                                                                  params[:treatment],
                                                                                  treatment_ids)
        else
          if params[:treatment].blank?
            conditions = ['citations.id = ? and treatments.id not in (?) and citations_sites_2.id != ?', 
                          session["citation"],
                          treatment_ids,
                          session["citation"] ]
          else
            conditions = ['(treatments.name like ? or treatments.definition like ? ) and citations.id = ? and treatments.id not in (?) and citations_sites_2.id != ?',
                          params[:treatment],
                          params[:treatment],
                          session["citation"],
                          treatment_ids,
                          session["citation"] ]
          end
          tts = Treatment.where(conditions).includes({:citations => {:sites => :citations} })
        end
        @other_treatments = tts.paginate :page => params[:page]
        
      else
        if !params[:treatment].blank?
          conditions = ['name like ? or definition like ?',params[:treatment],params[:treatment]]
        else
          conditions = []
        end
        @other_treatments = Treatment.paginate :page => params[:page], :conditions => conditions
      end
    else
      conditions = {}
      params.each do |k,v|
        next if !Treatment.column_names.include?(k)
        conditions[k] = v
      end
      logger.info conditions.to_yaml
      @treatments = Treatment.where(conditions)
    end


    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @treatments }
      format.csv  { render :csv => @treatments }
      format.json  { render :json => @treatments }
    end
  end

  # GET /treatments/1
  # GET /treatments/1.xml
  def show
    @treatment = Treatment.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @treatment }
      format.csv  { render :csv => @treatment }
      format.json  { render :json => @treatment }
    end
  end

  # GET /treatments/new
  # GET /treatments/new.xml
  def new
    @treatment = Treatment.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @treatment }
      format.csv  { render :csv => @treatment }
      format.json  { render :json => @treatment }
    end
  end

  # GET /treatments/1/edit
  def edit
    @management = Management.new 
    @treatment = Treatment.find(params[:id])
  end

  # POST /treatments
  # POST /treatments.xml
  def create
    @treatment = Treatment.new(params[:treatment])

    @treatment.user = current_user

    respond_to do |format|
      if @treatment.save
        # if they have a citation selected the relationship should be auto created!
        if !session["citation"].nil?
          @treatment.citations << Citation.find(session["citation"])
        end
        flash[:notice] = 'Treatment was successfully created.'
        format.html { redirect_to treatments_path }
        format.xml  { render :xml => @treatment, :status => :created, :location => @treatment }
        format.csv  { render :csv => @treatment, :status => :created, :location => @treatment }
        format.json  { render :json => @treatment, :status => :created, :location => @treatment }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @treatment.errors, :status => :unprocessable_entity }
        format.csv  { render :csv => @treatment.errors, :status => :unprocessable_entity }
        format.json  { render :json => @treatment.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /treatments/1
  # PUT /treatments/1.xml
  def update
    @treatment = Treatment.find(params[:id])

    params[:treatment].delete("user_id")

    respond_to do |format|
      if @treatment.update_attributes(params[:treatment])
        flash[:notice] = 'Treatment was successfully updated.'
        format.html { redirect_to( treatments_path ) }
        format.xml  { head :ok }
        format.csv  { head :ok }
        format.json  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @treatment.errors, :status => :unprocessable_entity }
        format.csv  { render :csv => @treatment.errors, :status => :unprocessable_entity }
        format.json  { render :json => @treatment.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /treatments/1
  # DELETE /treatments/1.xml
  def destroy
    @treatment = Treatment.find(params[:id])
    @treatment.managements.destroy
    @treatment.destroy

    respond_to do |format|
      format.html { redirect_to(treatments_url) }
      format.xml  { head :ok }
      format.csv  { head :ok }
      format.json  { head :ok }
    end
  end
end
