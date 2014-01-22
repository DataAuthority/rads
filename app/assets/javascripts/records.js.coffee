# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://coffeescript.org/
onLoad ->
  $("#records_nav select").change ->
    $(this).parent("form").submit()
  $("#records_nav input[type='submit']").hide()
