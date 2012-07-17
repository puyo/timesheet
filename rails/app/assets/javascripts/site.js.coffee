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
#= require "jquery-ui-1.8.21.custom.min"

## require "underscore"
## require "backbone"
## require "time_entries"

$ ->
  $('#sign_out').click ->
    $('.sign-in').show()
    $('.timesheet').hide()

  $('#sign_in').click ->
    $('.sign-in').hide()
    $('.timesheet').show()

  todoItemUrls = $.map($('[data-todo-item-url]'), (val, i) ->
    $(val).data('todo-item-url')
  )
  todoItemUrls = $.unique(todoItemUrls)
  $.each(todoItemUrls, (i, url) ->
    $.ajax(
      url: url
    ).done (data) ->
      name = data.todo_item.content
      $('.job_code a[data-todo-item-url="' + url + '"]').text(name)
      $('input[data-todo-item-url="' + url + '"]').val(name)
  )

  show_time_entry_edit = (id) ->
    time_entry_edit(id).show()
    time_entry_view(id).hide()

  hide_time_entry_edit = (id) ->
    time_entry_edit(id).show()
    time_entry_view(id).hide()
    $view = time_entry_view(id)
    $edit = time_entry_edit(id)
    $view.find('.loading').show()
    $view.show()
    $edit.hide()

  time_entry_view = (id) ->
    $('tr.time_entry[data-time-entry-id=' + id + ']')

  time_entry_edit = (id) ->
    $('tr.edit_time_entry[data-time-entry-id=' + id + ']')

  populate_view_from_edit = (id) ->
    $view = time_entry_view(id)
    $edit = time_entry_edit(id)
    $view.find('.date a').text($edit.find('.field.date input').val())
    $view.find('.hours a').text($edit.find('.field.hours input').val())
    $view.find('.description a').text($edit.find('.field.description input').val())

  setup_time_entry_edits = ->
    $('.edit_time_entry_link').click (e) ->
      e.preventDefault()
      id = $(e.target).data('time-entry-id')
      show_time_entry_edit(id)

    $('form.edit_basecamp_time_entry').submit (e) ->
      id = $(e.target).closest('tr.edit_basecamp_time_entry').data('time-entry-id')
      hide_time_entry_edit(id)

    $('form.edit_basecamp_time_entry').bind 'ajax:success', (e) ->
      $(@).find('.loading').hide()
      id = $(e.target).closest('tr.edit_basecamp_time_entry').data('time-entry-id')
      populate_view_from_edit(id)

    $('form.edit_basecamp_time_entry').bind 'ajax:failure', ->
      $(@).find('.loading').hide()
      id = $(e.target).closest('tr.edit_basecamp_time_entry').data('time-entry-id')
      time_entry_view(id).text('Error')

  setup_time_entry_edits()

  options = [
    '02A',
    '02B',
    '04B',
    '04I',
  ]

  $('#time_entry_job_code').autocomplete(options)

