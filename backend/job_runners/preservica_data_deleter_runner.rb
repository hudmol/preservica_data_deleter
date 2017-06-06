class PreservicaDataDeleterRunner < JobRunner

  register_for_job_type('preservica_data_deleter_job',
                        :allow_reregister => true,
                        :create_permissions => :administer_system,
                        :cancel_permissions => :administer_system)

  def run
    delete = @json.job.fetch('delete', false)

    log("Other Finding Aid Notes attached to Resources or AOs with content starting with https://preservica.library.yale.edu")
    Note.filter(Sequel.like(:notes, '%"type":"otherfindaid"%'))
      .filter(Sequel.like(:notes, '%"content":"https://preservica.library.yale.edu%'))
      .where(Sequel.|(Sequel.~({:resource_id => nil}), Sequel.~({:archival_object_id => nil})))
      .select(:id)
      .each do |note|

      DB.open do |db|
        db[:subnote_metadata].filter(:note_id => note.id).delete
      end
      Note[note.id].delete if delete
      log("  Note #{note.id}#{delete ? ' -- deleted' : ''}")
    end

    log("  ")

    Repository.each do |repo|
      break if self.canceled?
      log("--")
      log("Repository: #{repo.repo_code} (id=#{repo.id})")
      RequestContext.open(:repo_id => repo.id, :current_username => @job.owner.username) do
        log("DOs created by user preservicaprod")
        DigitalObject.filter(:repo_id => DigitalObject.active_repository)
          .filter(:created_by => 'preservicaprod')
          .select(:id, :digital_object_id).each do |dig|

          #DigitalObject.handle_delete([dig.id]) if delete
          DigitalObject[dig.id].delete if delete
          log("  #{dig.id} #{dig.digital_object_id}#{delete ? ' -- deleted' : ''}")
        end

        log("  ")

        log("DOs with a file_version with a file_uri starting with https://preservica.library.yale.edu")
        DigitalObject.filter(:repo_id => DigitalObject.active_repository)
          .join(:file_version, :digital_object_id => :digital_object__id)
          .filter(Sequel.like(:file_uri, 'https://preservica.library.yale.edu%'))
          .select(Sequel.qualify(:digital_object, :id), Sequel.qualify(:digital_object, :digital_object_id)).each do |dig|

          DigitalObject[dig.id].delete if delete
          log("  #{dig.id} #{dig.digital_object_id}#{delete ? ' -- deleted' : ''}")
        end
        
      end
    end

    self.success! unless self.canceled?
  end


  def log(s)
    Log.debug(s)
    @job.write_output(s)
  end


  def log_error(s, e = nil)
    log("  *** #{s}")
    Log.debug(e.backtrace.join("\n")) if e
  end
end
