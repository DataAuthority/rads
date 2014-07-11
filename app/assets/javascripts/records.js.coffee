# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://coffeescript.org/
onLoad ->
  $("#records_nav select").change ->
    $(this).parent("form").submit()
  $("#records_nav input[type='submit']").hide()
  $('div.dropzone:first').each ->
    dropzone_params = {}
    dropzone_params[$('meta[name=csrf-param]').attr("content")] = $('meta[name=csrf-token]').attr("content")
    selected_project = $('#record_filter_affiliated_with_project option[selected=selected]').val()
    if selected_project
      dropzone_params['record[project_affiliated_records_attributes][][project_id]'] = selected_project
    $('#record_filter_affiliated_with_project').change () ->
      selected_project = $('#record_filter_affiliated_with_project option[selected=selected]').val()
      if selected_project
        dropzone_params['record[project_affiliated_records_attributes][][project_id]'] = selected_project
      else
        delete dropzone_params['record[project_affiliated_records_attributes][][project_id]']

    $(".dropzone").dropzone
      autoProcessQueue: false
      init: () ->
        the_dz = this
        file_count = 0
        the_dz.on "addedfile", (file) -> 
          file_count++
          cur_file_num = file_count
          window.setTimeout () ->
            if cur_file_num == file_count
              if file_count < 4 ||
                 confirm("You are about to upload " + file_count + " files. Would you like to continue?")
                the_dz.processQueue()
              else
                the_dz.removeAllFiles()
              file_count = 0
              true
          , 3000
          true
        the_dz.on "complete", (file) ->
          the_dz.processQueue()
          true
        true
      params: dropzone_params
      url: '/records',
      method: 'POST',
      paramName: 'record[content]',
      forceFallback: false,
      uploadMultiple: false
    true
  true