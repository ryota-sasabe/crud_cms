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
    @search = search_params

    includes = @model.reflect_on_all_associations(:belongs_to).collect{ |item| item.name}
    @data = @model.search(ransack_search_params).result.includes(includes)
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
      crud_config = {}
      crud_config[:model] = {}
      crud_config[:model][:Article] = {}
      crud_config[:model][:Article][:table_label] = '記事'
      crud_config[:model][:Article][:publish_date] = {
        label: '公開日'
      }
      crud_config[:model][:Article][:author_id] = {
        label: '執筆者ID',
        options: {
          model: 'Author',
          label: 'name',
          value: 'id',
        }
      }

      crud_config[:model][:Author] = {}
      crud_config[:model][:Author][:table_label] = '著者'

      crud_config[:model][:Comment] = {}
      crud_config[:model][:Comment][:table_label] = 'コメント'

      @database = params[:database]
      @current_model_name = params[:model]
      @model = @current_model_name.constantize
      @columns = Module.const_get(@current_model_name).columns
      @fields = {}

      # テーブルのフィールド回す
      @columns.each do |item|
        field_name = item.name
        field = field_name.to_sym
        @fields[field] = {}
        @fields[field][:name] = item.name
        @fields[field][:type] = item.type
        @fields[field][:editable] = !field.in?(@non_editable_fields)
        @fields[field][:ransack_search_name] = field_name + '_cont'

        # @todo 書き方見直し
        if field_config = crud_config[:model][@current_model_name.to_sym][field]

          # フィールドの表示名
          @fields[field][:label] = field_config[:label] || field_name

          # options 項目取得
          if options = field_config[:options]
            model = options[:model].constantize

            # select の options 選択項目
            @fields[field][:options] = Hash[*model.pluck(options[:value], options[:label]).flatten]
          end
        end
      end

      # テーブル一覧作成
      # モデルが存在するもののみに限定
      # ただし、モデル名がテーブル名の単数系になっていないと取得できない
      @all_models = {}
      crud_config[:model].each do |model, item|
        model_name = model.to_s
        logger.debug(model_name)
        begin
          model_name.constantize
          @all_models[model_name.to_sym] = {}
          @all_models[model_name.to_sym][:name] = crud_config[:model][model_name.to_sym][:table_label]
        rescue => e
          logger.debug(model_name + ' の Model が存在しません')
        end
      end
    end

    def editable_params
      fields = @fields.keys
      fields.delete_if {|field| field.in?(@non_editable_fields)}
#      logger.debug(fields.inspect)
      params.require(@current_model_name).permit(fields)

    end

    def sort_column
      return 'id' if params[:sort].nil?
      @fields.keys.include?(params[:sort].to_sym) ? params[:sort] : 'id'
    end

    def sort_direction
      %w[asc desc].include?(params[:direction]) ?  params[:direction] : 'asc'
    end

    def search_params
      hash = {}
      return hash if !params[:search] || !params[:search].respond_to?(:require)
      params.require(:search).permit(@fields.keys).each do |key, value|
        hash[key.to_sym] = value
      end
      return hash
    end

    def ransack_search_params
      hash = {}
      search_params.each do |key, value|
        name = (key.to_s + '_cont').to_sym
        hash[name] = value
      end
#      Rails.logger.error(hash.inspect)
      return hash
    end
end
