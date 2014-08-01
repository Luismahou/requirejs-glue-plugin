define (require) ->

  Counter = require './Counter'

  class CounterProvider

    invoked: 0

    get: ->
      @invoked++
      new Counter()