# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://coffeescript.org/

$.update_annotation_params = (dropzone_params) ->
    $(".annotation_creator").each ->
      elem_id = $(this).attr('id')
      elem_num = parseInt(elem_id.replace(/record_filter_annotation_filter_terms_attributes_(\d+).*/m, '$1'))
      chosen_creator = $(this).val()
      if chosen_creator
        delete dropzone_params['record[annotations_attributes]['+elem_num+'][context]']
        delete dropzone_params['record[annotations_attributes]['+elem_num+'][term]']
      else
        chosen_context = $("#"+elem_id.replace(/created_by$/,'context')).val()
        if chosen_context
          dropzone_params['record[annotations_attributes]['+elem_num+'][context]'] = chosen_context
        else
          delete dropzone_params['record[annotations_attributes]['+elem_num+'][context]']
        chosen_term = $("#"+elem_id.replace(/created_by$/,'term')).val()
        if chosen_term
          dropzone_params['record[annotations_attributes]['+elem_num+'][term]'] = chosen_term
        else
          delete dropzone_params['record[annotations_attributes]['+elem_num+'][term]']

$.toggle_records_context = (context) ->
  if context == 'filter'
    $('span#annotation_creator_filter').show()
    $('fieldset.record_attribute_filters').show()
    $('fieldset.save_and_submit').show()
    $('div.dropzone').hide()
    $('#filter').hide()
    $('#upload').show()
  else if context == 'upload'
    $('span#annotation_creator_filter').hide()
    $('fieldset.record_attribute_filters').hide()
    $('fieldset.save_and_submit').hide()
    $('div.dropzone').show()
    $('#filter').show()
    $('#upload').hide()
  else
    $('span#annotation_creator_filter').show()
    $('fieldset.record_attribute_filters').show()
    $('fieldset.save_and_submit').show()
    $('div.dropzone').hide()
    $('#filter').hide()
    $('#upload').show()
  true

$.toggle_dropzone_for_project = (project_id) ->
  if project_id
    $.get "projects/"+project_id+"/can_affiliate_to", (can_affiliate) ->
      if can_affiliate == 'true'
        $('div#records_context').show()
      else
        $.toggle_records_context 'filter'
        $('div#records_context').hide()
  else
    $('div#records_context').show()

onLoad ->
  dropzone_params = {}
  $("a.remove_stored_query").click (event) ->
    link = $(this)
    $.override_remote_link link, event, () ->
        link.parent().remove()

  $('#finished_uploading').click ->
    $('#records_nav form').submit()
    false

  $("a.add_annotation_filter").click ->
    new_filter = $('div#annotation_filters .annotation_filter_fields:last').clone(true)
    new_filter.find('.record_filter_input').each ->
      elem_id = $(this).attr('id')
      elem_num = parseInt(elem_id.replace(/record_filter_annotation_filter_terms_attributes_(\d+).*/m, '$1')) + 1
      new_id = elem_id.replace('_' + (elem_num - 1) + '_', '_' + elem_num + '_')
      new_name = $(this).attr('name').replace('[' + (elem_num - 1) + ']', '[' + elem_num + ']')
      $(this).attr({'name': new_name, 'id': new_id}).val('')
    $('div#annotation_filters .annotation_filter_fields:last').after(new_filter)
    $('a.remove_annotation_filters').show()
    false

  $("a.remove_annotation_filters").hide()
  $("a.remove_annotation_filters").click ->
    $('span.annotation_filter_fields').each ->
      elem_id = $(this).find('.record_filter_input:first').attr('id')
      elem_num = parseInt(elem_id.replace(/record_filter_annotation_filter_terms_attributes_(\d+).*/m, '$1'))
      delete dropzone_params['record[annotations_attributes]['+elem_num+'][context]']
      delete dropzone_params['record[annotations_attributes]['+elem_num+'][term]']
      if elem_num > 0
        $(this).remove()
      else
        $(this).find('.record_filter_input').each ->
          $(this).val('')
          true
      true
    $(this).hide()
    false

  $("a.add_to_cart").click ->
    button = $(this)
    $.post $(this).attr('href'), (data) ->
      button.replaceWith "<p>"+data.message+"</p>"
      true
    , "json"
    false

  $("a.switch_records_context").click ->
    $.toggle_records_context $(this).attr('id')
    false

  $('div.dropzone:first').each ->
    dropzone_params[$('meta[name=csrf-param]').attr("content")] = $('meta[name=csrf-token]').attr("content")
    selected_project = $('#record_filter_affiliated_with_project option:selected').val()
    $.toggle_dropzone_for_project(selected_project)
    if selected_project
      dropzone_params['record[project_affiliated_records_attributes][][project_id]'] = selected_project
    $.update_annotation_params(dropzone_params)

    $('.annotation_term').change ->
      $.update_annotation_params(dropzone_params)

    $('.annotation_context').change ->
      $.update_annotation_params(dropzone_params)

    $('.annotation_creator').change ->
      $.update_annotation_params(dropzone_params)

    $('#record_filter_affiliated_with_project').change () ->
      selected_project = $('#record_filter_affiliated_with_project option:selected').val()
      $.toggle_dropzone_for_project(selected_project)
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
          $('#finished_uploading').show()
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
      url: window.location.pathname
      method: 'POST',
      paramName: 'record[content]',
      forceFallback: false,
      uploadMultiple: false
    true
  $.toggle_records_context 'filter'
  true