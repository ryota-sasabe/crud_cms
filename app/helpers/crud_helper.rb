module CrudHelper

  def associate_type(model_from, model_to)
    @associate_models[model_from].each do |item|
      if item[:class_name] == model_to
        return item[:type]
      end
    end
    nil
  end
end
