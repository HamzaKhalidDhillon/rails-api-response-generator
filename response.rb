module Response
  def json_response(object, includes: nil, each_serializer: nil, serializer: nil, meta: {}, status: 200, page: nil,
                    per: nil, serializer_params: {},  scope: {}, apply_order: true, sort_column: nil,
                    sort_direction: 'desc', apply_page: true,
                    **kwargs)
    response = {}

    page = page || 1
    per = per || 10
    
    response[:scope] = scope
    if each_serializer.present?
      relation = object
      if apply_order and sort_column.present? and relation.column_names.include?(sort_column)
        relation = relation.reorder(nil)
        relation = relation.order("#{sort_column} #{sort_direction || 'desc'}")
      end
      page = "1" if object.count <= per.to_i
      relation = relation.paginate(page: page, per_page: per) if apply_page
      response[:json] = relation
      response[:each_serializer] = each_serializer

      meta.merge!(page: page.to_i, per_page: per.to_i, total_count: object.count)
      meta.merge!(total_pages: response[:json].total_pages) if apply_page
    elsif serializer.present?
      response[:serializer] = serializer
      response[:json] = object
    else
      response[:json] = object
    end

    response[:include] = includes if includes.present?
    response[:meta] = meta
    response[:status] = status
    meta.merge!(status: status)
    response[:adapter] = :json

    serializer_params.each do |key, value|
      next unless value
      response[key.to_sym] = value
    end

    kwargs.keys do |key|
      response[:json][key]= kwargs[key]
    end

    render response
  end

  def error_response(message, meta: {}, status: :unprocessable_entity)
    response = {}

    response[:errors] = [{ message: message, meta: meta }]
    response[:status] = status

    json_response(response, status: status)
  end

  def custom_response(json)
    render(json: json)
  end

  def array_json_response(object, name: nil, meta: {}, status: 200, page: nil, per: nil)
    response = {}

    page = page || 1
    per = per || 20

    response[name.to_sym] = object.paginate(page: page, per_page: per)
    meta.merge!(page: page.to_i, per_page: per.to_i,
                total_count: object.length,
                total_pages: response[name.to_sym].total_pages,
                status: status)

    response[:meta] = meta
    response[:adapter] = :json

    render(json: response)
  end
end
