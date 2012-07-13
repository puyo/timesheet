#= require "bootstrap/bootstrap-transition"
#= require "bootstrap/bootstrap-alert"
#= require "bootstrap/bootstrap-button"
#= require "bootstrap/bootstrap-carousel"
#= require "bootstrap/bootstrap-collapse"
#= require "bootstrap/bootstrap-dropdown"
#= require "bootstrap/bootstrap-modal"
#= require "bootstrap/bootstrap-tooltip"
#= require "bootstrap/bootstrap-popover"
#= require "bootstrap/bootstrap-scrollspy"
#= require "bootstrap/bootstrap-tab"
#= require "bootstrap/bootstrap-typeahead"
#= require "jquery-ui-1.8.19.custom.min"

$ ->
  $('#sign_out').click ->
    $('.sign-in').show()
    $('.timesheet').hide()
  $('#sign_in').click ->
    $('.sign-in').hide()
    $('.timesheet').show()
  $('[data-project-url]').each ->
    $el = $(@)
    $.ajax(
      url: $el.data('project-url')
    ).done (data) ->
      $el.text(data.project.name)
  $('[data-todo-item-url]').each ->
    $el = $(@)
    $.ajax(
      url: $el.data('todo-item-url')
    ).done (data) ->
      console.log data
      $el.text(data.todo_item.content)

  #$('#filter_date').datepicker(dateFormat: 'yy-mm-dd')
  #$('#new_date').datepicker(dateFormat: 'yy-mm-dd')
