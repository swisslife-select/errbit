module AppCopy
  class << self
    def deep_copy_attributes(recipient, donor)
      attrs = donor.attributes.except 'id', 'name', 'created_at', 'updated_at'
      recipient.assign_attributes attrs

      donor.watchers.each do |w|
        watchers_attrs = nested_model_attributes(w)
        recipient.watchers.build watchers_attrs
      end

      if donor.issue_tracker
        issue_tracker_attrs = nested_model_attributes donor.issue_tracker
        # build_association don't assign type in rails 3
        issue_tracker = donor.issue_tracker.class.new issue_tracker_attrs
        recipient.issue_tracker = issue_tracker
      end

      if donor.notification_service
        notification_service_attrs = nested_model_attributes donor.notification_service
        notification_service = donor.notification_service.class.new notification_service_attrs
        recipient.notification_service = notification_service
      end
    end

    private
    def nested_model_attributes(model)
      model.attributes.except('id', 'app_id', 'created_at', 'updated_at')
    end
  end
end