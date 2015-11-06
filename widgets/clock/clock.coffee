class Dashing.Clock extends Dashing.Widget

  ready: ->
    setInterval(@startTime, 500)

  startTime: =>
    now = moment()

    @set('time', now.format('hh:mm'))
    @set('date', now.format("dddd, MMMM Do YYYY"))
