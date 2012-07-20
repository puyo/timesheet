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
    tuples = $('[data-todo-item-id][data-project-id]').map ->
      $el = $(@)
      $el.data('project-id') + '-' + $el.data('todo-item-id')
    for tuple in $.unique(tuples)
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

  @loadProjectNames: ->
    projectIds = $.unique($.map($('[data-project-id]'), (el) -> $(el).data('project-id')))
    $.each projectIds, (i, projectId) =>
      @updateEntriesWithProjectName(projectId, @projectsIndex[projectId].name)

  @updateEntriesWithJobCode: (projectId, todoItemId, jobCode) ->
    selector = '[data-todo-item-id="' + todoItemId + '"][data-project-id="' + projectId + '"]'
    $('.job_code' + selector).text(jobCode)
    $('input' + selector).val(jobCode)

  @updateEntriesWithProjectName: (projectId, projectName) ->
    selector = '[data-project-id="' + projectId + '"]'
    $('.project' + selector).text(projectName)

  @addEntry: (id, html) ->
    $('.timesheet table.table').append(html)
    $el = $('#time_entry_' + id)
    projectId = $el.data('project-id')
    todoItemId = $el.data('todo-item-id')
    key = projectId + '-' + todoItemId
    jobCode = @jobCodeIndex[key]
    if jobCode
      @updateEntriesWithJobCode(projectId, todoItemId, jobCode)
    else
      @loadJobCode(projectId, todoItemId)
    project = @projectsIndex[projectId]
    if project
      @updateEntriesWithProjectName(projectId, project.name)
    @recalculateTotals()

  @removeEntry: (id) ->
    $entry = $('#time_entry_' + id)
    $entry.fadeOut "normal", =>
      $entry.remove()
      @recalculateTotals()
    $('#edit_time_entry_' + id).remove()

  @recalculateTotals: ->
    $('.totals').remove()
    dates = $('.time_entry').map ->
      $(@).data('date')
    dates = $.unique(dates)
    for date in dates
      sum = 0.0
      entries = $('.time_entry[data-date="' + date + '"]')
      hours = entries.each ->
        sum += Number($(@).find('.hours').text())
      html = '<tr class="totals"><td colspan="4">' + date + '</td><td colspan="3">' + sum + '</td></tr>'
      entries.last().after(html)

  @disableCreate: ->
    $('#new_time_entry').find('input[type=submit]').attr('disabled', 'disabled')

  @enableCreate: ->
    $('#new_time_entry').find('input[type=submit]').attr('disabled', null)

window.Timesheet = Timesheet

$ ->
  Timesheet.loadJobCodes()
  Timesheet.loadProjectNames()
  Timesheet.recalculateTotals()

  $('#sign_out').click ->
    $('.sign-in').show()
    $('.timesheet').hide()

  $('#sign_in').click ->
    $('.sign-in').hide()
    $('.timesheet').show()

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
    $('#time_entry_' + id)

  timeEntryEdit = (id) ->
    $('#edit_time_entry_' + id)

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
  $('input.filter.date').datepicker()
  $('input.filter.date').datepicker()

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

  $('#new_time_entry').submit ->
    Timesheet.disableCreate()
