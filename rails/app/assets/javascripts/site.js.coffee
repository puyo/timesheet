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
#= require "sort-elements"

class Timesheet
  @jobCodeIndex: {}
  @projectsIndex: {}
  @peopleIndex: {}
  @projects: []

  # TODO: nicer labels?
  #{label: '02A - Lunch', value:'02A'},
  #{label: '02B - Personal Time', value:'02B'},
  #{label: '03A - Personal Time', value:'02B'},
  @jobCodes = [
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
    for projectId in projectIds
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
    @refreshEntry(id)

  @updateEntry: (id, html) ->
    $view = @timeEntryView(id)
    $parent = $view.parent()
    index = $parent.children().index($view)
    $edit = @timeEntryEdit(id)
    $view.remove()
    $edit.remove()
    $parent.find('tr').eq(index).before(html)
    @refreshEntry(id)

  @refreshEntry: (id) ->
    $view = @timeEntryView(id)
    projectId = $view.data('project-id')
    todoItemId = $view.data('todo-item-id')
    key = projectId + '-' + todoItemId
    jobCode = @jobCodeIndex[key]
    if jobCode
      @updateEntriesWithJobCode(projectId, todoItemId, jobCode)
    else
      @loadJobCode(projectId, todoItemId)
    project = @projectsIndex[projectId]
    if project
      @updateEntriesWithProjectName(projectId, project.name)
    @resort()
    @updateEntriesWithProjects()
    @updateEntriesWithPeople()

  @removeEntry: (id) ->
    $view = @timeEntryView(id)
    $entry.fadeOut "normal", =>
      $entry.remove()
      @resort()
    @timeEntryEdit(id).remove()

  @sortKey: (tr) ->
    $tr = $(tr)
    result = $tr.data('date')
    if $tr.hasClass('edit_time_entry')
      result += '-2'
    else
      result += '-1'
    return result

  @resort: ->
    $('.totals').remove()
    $entries = $('.time_entry')
    $entries.sortElements (a, b) =>
      @sortKey(a) > @sortKey(b) ? 1 : -1
    dates = $entries.map ->
      $(@).data('date')
    dates = $.unique(dates)
    for date in dates
      entries = $('.time_entry[data-date="' + date + '"]')
      sum = 0.0
      for entry in entries
        sum += Number($(entry).find('.hours').text())
      html = '<tr class="totals"><td colspan="4">' + date + '</td><td colspan="3">' + sum + '</td></tr>'
      $('.edit_time_entry[data-date="' + date + '"]').last().after(html)

  @disableCreate: ->
    # still allows hitting enter...
    #$('#new_time_entry').find('input[type=submit]').attr('disabled', 'disabled')

  @enableCreate: ->
    #$('#new_time_entry').find('input[type=submit]').attr('disabled', null)

  @updateEntriesWithProjects: () ->
    for e in $('.field.project_id select[data-project-id]')
      $select = $(e)
      selectedId = Number($select.data('project-id'))
      for project in @projects
        $select.data('project-id', null).append($('<option>', value: project.id, selected: project.id == selectedId).text(project.name))

  @updateEntriesWithPeople: () ->
    for e in $('.field.person_id select[data-person-id]')
      $select = $(e)
      selectedId = Number($select.data('person-id'))
      for person in @people
        $select.data('person-id', null).append($('<option>', value: person.id, selected: person.id == selectedId).text(person.name))

  @showTimeEntryEdit: (id) ->
    @timeEntryEdit(id).show()
    @timeEntryView(id).hide()

  @hideTimeEntryEdit: (id) ->
    @timeEntryEdit(id).show()
    @timeEntryView(id).hide()
    $view = @timeEntryView(id)
    $edit = @timeEntryEdit(id)
    $view.show()
    $edit.hide()

  @timeEntryView: (id) ->
    $('#time_entry_' + id)

  @timeEntryEdit: (id) ->
    $('#edit_time_entry_' + id)

window.Timesheet = Timesheet

$ ->
  Timesheet.loadJobCodes()
  Timesheet.loadProjectNames()
  Timesheet.resort()
  Timesheet.updateEntriesWithProjects()
  Timesheet.updateEntriesWithPeople()

  $('#sign_out').click ->
    $('.sign-in').show()
    $('.timesheet').hide()

  $('#sign_in').click ->
    $('.sign-in').hide()
    $('.timesheet').show()

  $('body').on 'click', '.time_entry_edit', (e) ->
    e.preventDefault()
    id = $(e.target).data('time-entry-id')
    Timesheet.showTimeEntryEdit(id)

  $('body').on 'click', '.time_entry_cancel', (e) ->
    e.preventDefault()
    id = $(e.target).closest('[data-time-entry-id]').data('time-entry-id')
    Timesheet.hideTimeEntryEdit(id)

  $('body').on 'focus', 'input[name="time_entry[job_code]"]', ->
    $(this).autocomplete(source: Timesheet.jobCodes)

  $.datepicker.setDefaults(dateFormat: 'yy-mm-dd')

  $('input.filter.date').datepicker()

  $('body').on 'focus', 'input[name="time_entry[date]"]', ->
    $(this).datepicker().datepicker('show')
    true

  $('#new_time_entry').submit ->
    Timesheet.disableCreate()
