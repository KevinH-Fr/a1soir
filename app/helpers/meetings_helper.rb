module MeetingsHelper

    def active_date_range_class(type)
        params[:type] == type ?  'btn btn-sm btn-dark' : 'btn btn-sm btn-outline-dark'
    end
end
