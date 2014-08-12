# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://coffeescript.org/
onLoad ->
  $("a.destroy_annotation").click (event) ->
    link = $(this)
    $.override_remote_link link, event, () ->
        link.parent().parent().remove()
