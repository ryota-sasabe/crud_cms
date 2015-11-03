class CrudController < ApplicationController
  helper_method :sort_column, :sort_direction

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
                .order(sort_column + ' ' + sort_direction)
                .page(params[:page])
                .per(10)
    @column_properties = %w{name type sql_type null limit precision scale default}

  end

  def show
  end

  def new
#    flash[:notice] = "aaoaoao"
    @data = @model.new
  end

  def create
    @data = @model.new(editable_params)
    if @data.save
      redirect_to({:action => "edit_complete", :id => @data.id}, notice: 'データの新規登録が完了しました。')
    else
      render action: 'new'
    end
  end

  def edit
    @id = params[:id]
    @data = @model.find(@id)
  end

  def update
    @id = params[:id]
    @data = @model.find(@id)

    if @data.update(editable_params)
      redirect_to({:action => "edit_complete", :id => @id}, notice: 'データの更新が完了しました。')
    else
      render action: 'edit'
    end
  end

  def edit_complete

  end

  private
    def initialize_table ()
      # とりあえず
      @non_editable_fields = ['id', 'created_at', 'updated_at']

      # テーブルごと設定 後で切り出す
      @config = {}
      @config[:tables] = {}
      @config[:tables][:articles] = {}
      @config[:tables][:articles][:table_label] = '記事'
      @config[:tables][:articles][:writer_id] = {
        :options => {
          :table => 'persons',
          :label => 'name',
          :value => 'id',
        }
      }

      @config[:tables][:people] = {}
      @config[:tables][:people][:table_label] = '人'

      @database = params[:database]
      @table = params[:table]
      @model_name = @table.classify
      @model = @model_name.constantize
      @columns = Module.const_get(@model_name).columns
      @fields = {}

      # テーブルのフィールド回す
      @columns.each do |item|
        field_name = item.name
        @fields[field_name] = {}
        @fields[field_name][:type] = item.type
        @fields[field_name][:editable] = !field_name.in?(@non_editable_fields)

        # options 項目取得
        # @todo 書き方見直し
        if config = @config[:tables][:articles][field_name.to_sym]

          if options = config[:options]
            model_name = options[:table].classify
            model = model_name.constantize
            @fields[field_name][:options] = model.pluck(options[:value], options[:label])
          end
        end
      end

      # テーブル一覧作成
      # モデルが存在するもののみに限定
      # ただし、モデル名がテーブル名の単数系になっていないと取得できない
      @database_tables = {}
      ActiveRecord::Base.connection.tables.each do |table_name|
        logger.debug(table_name.classify)
        begin
          table_name.classify.constantize
          @database_tables[table_name] = {}
          @database_tables[table_name][:name] = @config[:tables][table_name.to_sym][:table_label]
        rescue => e
          logger.debug(table_name + ' の Model が存在しません')
        end
      end
    end

    def editable_params
      fields = @fields.keys
      fields.delete_if {|field| field.in?(@non_editable_fields)}
#      logger.debug(fields.inspect)
      params.require(@model_name).permit(fields)
    end

    def sort_column
      @fields.keys.include?(params[:sort]) ? params[:sort] : "id"
    end

    def sort_direction
      %w[asc desc].include?(params[:direction]) ?  params[:direction] : "asc"
    end

end
