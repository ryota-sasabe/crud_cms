class CrudController < ApplicationController
  before_action :initialize_table


  def index

    # search
    if params[:search]
#      @cond = .delete_if {|field, value| value.blank?}.symbolize_keys

      where = []
      conditions = []
      params[:search].each do |field, value|
        next if value.blank?
        case @fields[field][:type]
          when :string
            where.push(field + ' like ?')
            value = '%' + value + '%'
          when :integer
            where.push(field + ' = ?')
          else
            where.push(field + ' = ?')
        end
        conditions.push(value)
      end
#      logger.debug(where.join(' and '))
      conditions.unshift(where.join(' and '))
    end

#    logger.debug(conditions.to_s)

    @data = @model.where(conditions)
    @column_properties = %w{name type sql_type null limit precision scale default}

  end

  def show
  end

  def new

  end

  def edit
    @id = params[:id]
    @data = @model.find(@id)
  end

  def edit_complete

  end

  def create
    @data = @model.new(editable_params)
    if @data.save
      redirect_to :action => "edit_complete", :id => @data.id, notice: 'Item was successfully created.'
    else
      render action: 'new'
    end
  end

  def update
    @id = params[:id]
    @data = @model.find(@id)

    if @data.update(editable_params)
      redirect_to :action => "edit_complete", :id => @id, notice: 'Item was successfully created.'
    else
      render action: 'edit'
    end

  end

  private
    def initialize_table ()
      @database = params[:database]
      @table = params[:table]
      @model_name = @table.classify
      @model = @model_name.constantize
      @columns = Module.const_get(@model_name).columns
      @fields = {}
      @columns.each do |item|
        field_name = item.name
        @fields[field_name] = {}
        @fields[field_name][:type] = item.type
        @fields[field_name][:editable] = !field_name.in?(['created_at', 'updated_at'])
      end
    end

    def editable_params
      fields = @fields.keys
      fields.delete_if {|field| field.in?(['created_at', 'updated_at'])}
#      logger.debug(fields.inspect)
      params.require(@model_name).permit(fields)
    end

end
