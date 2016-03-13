class CrudController < ApplicationController
  helper_method :sort_column, :sort_direction

  before_action :initialize_table

  def index

    # 表示列
    @list_fields = []
    if params[:list_fields]
      params[:list_fields].each do |model_name, item|
        item.symbolize_keys.keys.each do |field|
          @list_fields.push({:model => model_name.to_sym, :field => field})
        end
      end
    else
#      @list_fields = @fields[@current_model_name].keys
      @fields.each do |model_name, item|
        item.each do |field, config|
          @list_fields.push({:model => model_name, :field => field})
        end
      end
    end

    # 検索
    @search = search_params

    includes = @model.reflect_on_all_associations(:belongs_to).collect{ |item| item.class_name.to_sym}
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
      crud_config[:model][:Article][:writer_id] = {
        label: '執筆者ID',
        options: {
          model: 'Person',
          label: 'name',
          value: 'id',
        }
      }

      crud_config[:model][:Person] = {}
      crud_config[:model][:Person][:table_label] = '人'

      @database = params[:database]
      @current_model_name = params[:model].to_sym


      @model = @current_model_name.to_s.constantize

      @associate_model_names = @model.reflect_on_all_associations().collect{ |item| item.class_name.to_sym}

      # 現在のモデル + 関連モデル情報取得
      @table_columns = {}
      @fields = {}
      ([@current_model_name] + @associate_model_names).each do |model_name|
        model_name.to_s.constantize
        @table_columns[model_name] = Module.const_get(model_name.to_s).columns

        # テーブルのフィールド回す
        @fields[model_name] = {}
        @table_columns[model_name].each do |item|
          field_name = item.name
          field = field_name.to_sym
          @fields[model_name][field] = {}
          @fields[model_name][field][:name] = item.name
          @fields[model_name][field][:type] = item.type
          @fields[model_name][field][:editable] = !field.in?(@non_editable_fields)

          if field_config = crud_config[:model][@current_model_name][field]

            # フィールドの表示名
            @fields[model_name][field][:label] = field_config[:label] || field_name

            # options 項目取得
            if options = field_config[:options]
              model = options[:model].constantize

              # select の options 選択項目
              @fields[model_name][field][:options] = Hash[*model.pluck(options[:value], options[:label]).flatten]
            end
          end
        end

      end



      # 全モデル情報取得
      @all_models = {}
      ActiveRecord::Base.subclasses.each do |model_class|
        model_name = model_class.table_name.classify.to_sym
        logger.debug(model_name)
        begin
#          model_name.constantize
          @all_models[model_name] = {}
          @all_models[model_name][:name] = crud_config[:model][model_name][:table_label]
        rescue => e
          logger.debug(model_name.to_s + ' の Model が存在しません')
        end
      end


    end

    def editable_params
      fields = @fields[@current_model_name].keys
      fields.delete_if {|field| field.in?(@non_editable_fields)}
#      logger.debug(fields.inspect)
      params.require(@current_model_name).permit(fields)

    end

    def sort_column
      return 'id' if params[:sort].nil?
      @fields[@current_model_name].keys.include?(params[:sort].to_sym) ? params[:sort] : 'id'
    end

    def sort_direction
      %w[asc desc].include?(params[:direction]) ?  params[:direction] : 'asc'
    end

    def search_params
      hash = {}
      return hash if !params[:search] || !params[:search][@current_model_name] || !params[:search][@current_model_name].respond_to?(:require)
      params.require(:search).each do |model_name, item|
        hash[model_name.to_sym] = {}
        item.permit(@fields[model_name.to_sym].keys).each do |key, value|
          hash[model_name.to_sym][key.to_sym] = value
        end
      end
      return hash
    end

    def ransack_search_params
      hash = {}
      search_params.each do |model_name, item|
        hash[model_name] = {}
        item.each do |key, value|
          field = key.to_s
          case @fields[model_name][key][:type]
          when :string, :text
            name = field + '_cont'
          when :integer, :datetime, :boolean
            name = field + '_in'
          else
            Rails.logger.debug('kokokita')
          end
          hash[name.to_sym] = value
          # hash[(model_name.to_s.tableize + '_' + name).to_sym] = value
        end
      end
      return hash
    end
end
