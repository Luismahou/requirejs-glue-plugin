define (require) ->

  Bar = require 'glue!./Bar'
  Foo = require './Foo'

  class DependentFooProvider

    get: ->
      new Foo(new Bar())
