module CrudHelper

  def associate_type(model_from, model_to)
    @associate_models[model_from].each do |item|
      if item[:class_name] == model_to
        return item[:type]
      end
    end
    nil
  end

  def foreign_key_to_modelname(model, field)
    @foreign_keys ||= {}
    if @foreign_keys.include?(model)
      return @foreign_keys[model][field] || nil
    end
    @foreign_keys[model] = {}
    model.to_s.constantize.reflect_on_all_associations(:belongs_to).each do |item|
      @foreign_keys[model][item.options[:foreign_key]] = item.class_name.to_sym
    end
    @foreign_keys[model][field]
  end
end
