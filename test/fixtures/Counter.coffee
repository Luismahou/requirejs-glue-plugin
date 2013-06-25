define (require) ->

  counter = 0

  class Counter
    constructor: ->
      @counter = counter++

    sayHello: ->
      'hello'
