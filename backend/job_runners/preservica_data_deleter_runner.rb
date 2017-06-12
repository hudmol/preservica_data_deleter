class PreservicaDataDeleterRunner < JobRunner

  register_for_job_type('preservica_data_deleter_job',
                        :allow_reregister => true,
                        :create_permissions => :administer_system,
                        :cancel_permissions => :administer_system)

  def run
    unless AppConfig.has_key?(:preservica_data_deleter_match_url)
      log("*** Please set AppConfig[:preservica_data_deleter_match_url]. Aborting. ***")
      self.finish!(:failed)
    end

    match_url = AppConfig[:preservica_data_deleter_match_url]

    delete = @json.job.fetch('delete', false)

    if delete
      unless @json.job['confirmation_string'] == Time.now.to_s.split.first + ' ' + @job.owner.username
        log("*** Incorrect confirmation string. Aborting. ***")
        self.finish!(:failed)
        return
      end
    end

    log("Other Finding Aid Notes attached to Resources or AOs with content starting with #{match_url}")
    Note.filter(Sequel.like(:notes, '%"type":"otherfindaid"%'))
      .filter(Sequel.like(:notes, '%"content":"#{match_url}%'))
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
      log("  ")
      log("--")
      log("Repository: #{repo.repo_code} (id=#{repo.id})")
      RequestContext.open(:repo_id => repo.id, :current_username => @job.owner.username) do
        log("DOs created by user preservicaprod")
        DigitalObject.filter(:repo_id => DigitalObject.active_repository)
          .filter(:created_by => 'preservicaprod')
          .select(:id, :digital_object_id).each do |dig|

          DigitalObject[dig.id].delete if delete
          log("  #{dig.id} #{dig.digital_object_id}#{delete ? ' -- deleted' : ''}")
        end

        log("  ")

        log("DOs with a file_version with a file_uri starting with #{match_url}")
        DigitalObject.filter(:repo_id => DigitalObject.active_repository)
          .join(:file_version, :digital_object_id => :digital_object__id)
          .filter(Sequel.like(:file_uri, '#{match_url}%'))
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

end
