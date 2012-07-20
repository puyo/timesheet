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
#= require "unique"

## require "underscore"
## require "backbone"
## require "time_entries"

class Timesheet
  @jobCodeIndex: {}
  @projectsIndex: {}
  @peopleIndex: {}

  @addJobCode: (projectId, todoItemId, jobCode) ->
    @jobCodeIndex[projectId + '-' + todoItemId] = jobCode
    @updateEntriesWithJobCode(projectId, todoItemId, jobCode)

  @loadJobCodes: ->
    tuples = $.map $('[data-todo-item-id][data-project-id]'), (el) ->
      $el = $(el)
      $el.data('project-id') + '-' + $el.data('todo-item-id')
    tuples = $.unique(tuples)
    $.each tuples, (i, tuple) =>
      vals = tuple.split('-')
      projectId = vals[0]
      todoItemId = vals[1]
      @loadJobCode(projectId, todoItemId)

  @loadJobCode: (projectId, todoItemId) ->
    url = '/projects/' + projectId + '/todo_items/' + todoItemId + '.json'
    $.ajax(
      url: url
    ).done (data) =>
      jobCode = data.todo_item.content
      @addJobCode(projectId, todoItemId, jobCode)

  @updateEntriesWithJobCode: (projectId, todoItemId, jobCode) ->
    selector = '[data-todo-item-id="' + todoItemId + '"][data-project-id="' + projectId + '"]'
    $('.job_code a' + selector).text(jobCode)
    $('input' + selector).val(jobCode)

  @entryAdded: (id) ->
    $el = $('#time_entry_' + id)
    projectId = $el.data('project-id')
    todoItemId = $el.data('todo-item-id')
    key = projectId + '-' + todoItemId
    jobCode = @jobCodeIndex[key]
    if jobCode
      @updateEntriesWithJobCode(projectId, todoItemId, jobCode)
    else
      @loadJobCode(projectId, todoItemId)

window.Timesheet = Timesheet

$ ->
  $('#sign_out').click ->
    $('.sign-in').show()
    $('.timesheet').hide()

  $('#sign_in').click ->
    $('.sign-in').hide()
    $('.timesheet').show()

  Timesheet.loadJobCodes()

  showTimeEntryEdit = (id) ->
    timeEntryEdit(id).show()
    timeEntryView(id).hide()

  hideTimeEntryEdit = (id) ->
    timeEntryEdit(id).show()
    timeEntryView(id).hide()
    $view = timeEntryView(id)
    $edit = timeEntryEdit(id)
    $view.find('.loading').show()
    $view.show()
    $edit.hide()

  timeEntryView = (id) ->
    $('tr.time_entry[data-time-entry-id=' + id + ']')

  timeEntryEdit = (id) ->
    $('tr.edit_time_entry[data-time-entry-id=' + id + ']')

  populateViewFromEdit = (id) ->
    $view = timeEntryView(id)
    $edit = timeEntryEdit(id)
    $view.find('.date a').text($edit.find('.field.date input').val())
    $view.find('.hours a').text($edit.find('.field.hours input').val())
    $view.find('.description a').text($edit.find('.field.description input').val())

  setupTimeEntryEdits = ->
    $('.edit_time_entry_link').click (e) ->
      e.preventDefault()
      id = $(e.target).data('time-entry-id')
      showTimeEntryEdit(id)

    $('form.edit_basecamp_time_entry').submit (e) ->
      id = $(e.target).closest('tr.edit_basecamp_time_entry').data('time-entry-id')
      hideTimeEntryEdit(id)

    $('form.edit_basecamp_time_entry').bind 'ajax:success', (e) ->
      $(@).find('.loading').hide()
      id = $(e.target).closest('tr.edit_basecamp_time_entry').data('time-entry-id')
      populateViewFromEdit(id)

    $('form.edit_basecamp_time_entry').bind 'ajax:failure', ->
      $(@).find('.loading').hide()
      id = $(e.target).closest('tr.edit_basecamp_time_entry').data('time-entry-id')
      timeEntryView(id).text('Error')

  setupTimeEntryEdits()

  $.datepicker.setDefaults(dateFormat: 'yy-mm-dd')
  $('input[name="time_entry[date]"]').datepicker()

  #{label: '02A - Lunch', value:'02A'},
  #{label: '02B - Personal Time', value:'02B'},
  #{label: '03A - Personal Time', value:'02B'},

  options = [
    '01A',
    '01B',
    '01C',
    '01D',

    '02A',
    '02B',

    '03A',
    '03B',
    '03B-2',
    '03C',
    '03D',
    '03E',
    '03F',
    '03G',
    '03H',

    '04A',
    '04A-2',
    '04B',
    '04B-2',
    '04C',
    '04C-2',
    '04D',
    '04D-2',
    '04F',
    '04F-2',
    '04G',
    '04H',
    '04PP',
    '04PP-2',
    '04I',
    '04I-2',

    '05A',
    '05B',
    '05C',
  ]

  $('#time_entry_job_code').autocomplete(source: options)

