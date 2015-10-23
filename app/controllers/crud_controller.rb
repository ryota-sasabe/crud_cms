class CrudController < ApplicationController

  def index
    @table = params[:table]
    model_name = @table.classify
    @model = model_name.constantize
    @columns = Module.const_get(model_name).columns
    @fields = {}
    @columns.each do |item|
      @fields[item.name] = {}
      @fields[item.name][:type] = item.type
    end


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
  end

  def create
  end

  def update
  end
end
