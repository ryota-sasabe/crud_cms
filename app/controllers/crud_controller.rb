class CrudController < ApplicationController
  helper_method :sort_column, :sort_direction

  before_action :initialize_table

  def index

    # 表示列
    if params[:list_fields]
      @list_fields = params[:list_fields].symbolize_keys.keys
    else
      @list_fields = @fields.keys
    end

    # 検索
    @search = {}
    if params[:search]
#      @cond = .delete_if {|field, value| value.blank?}.symbolize_keys

      where = []
      conditions = []
      params[:search].each do |field_name, value|
        field = field_name.to_sym
        next unless @fields.key?(field)
        next if value.blank?
        @search[field] = value
        case @fields[field][:type]
          when :string
            where.push(field_name + ' like ?')
            value = '%' + value + '%'
          when :integer
            where.push(field_name + ' = ?')
          else
            where.push(field_name + ' = ?')
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
      redirect_to({:action => "edit_complete", id: @data.id}, notice: 'データの新規登録が完了しました。')
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
      redirect_to({:action => "edit_complete", id: @id}, notice: 'データの更新が完了しました。')
    else
      render action: 'edit'
    end
  end

  def edit_complete
    @id = params[:id]
  end

  private
    def initialize_table ()
      # とりあえず
      @non_editable_fields = [:id, :created_at, :updated_at]

      # テーブルごとの設定項目 後で切り出す
      table_config = {}
      table_config[:tables] = {}
      table_config[:tables][:articles] = {}
      table_config[:tables][:articles][:table_label] = '記事'
      table_config[:tables][:articles][:publish_date] = {
        label: '公開日'
      }
      table_config[:tables][:articles][:writer_id] = {
        label: '執筆者ID',
        options: {
          table: 'persons',
          label: 'name',
          value: 'id',
        }
      }

      table_config[:tables][:people] = {}
      table_config[:tables][:people][:table_label] = '人'

      @database = params[:database]
      @table = params[:table]
      @model_name = @table.classify
      @model = @model_name.constantize
      @columns = Module.const_get(@model_name).columns
      @fields = {}

      # テーブルのフィールド回す
      @columns.each do |item|
        field_name = item.name
        field = field_name.to_sym
        @fields[field] = {}
        @fields[field][:name] = item.name
        @fields[field][:type] = item.type
        @fields[field][:editable] = !field.in?(@non_editable_fields)

        # @todo 書き方見直し
        if field_config = table_config[:tables][@table.to_sym][field]

          # フィールドの表示名
          @fields[field][:label] = field_config[:label] || field_name

          # options 項目取得
          if options = field_config[:options]
            model_name = options[:table].classify
            model = model_name.constantize

            # select の options 選択項目
            @fields[field][:options] = Hash[*model.pluck(options[:value], options[:label]).flatten]
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
          @database_tables[table_name][:name] = table_config[:tables][table_name.to_sym][:table_label]
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
      return 'id' if params[:sort].nil?
      @fields.keys.include?(params[:sort].to_sym) ? params[:sort] : 'id'
    end

    def sort_direction
      %w[asc desc].include?(params[:direction]) ?  params[:direction] : 'asc'
    end

end
