define ['glue!binder', 'glue!fixtures/Counter'], (binder, Counter) ->

  describe 'singleton', ->
    afterEach ->
      binder.clearBindings()

    it 'should return same instance', ->
      expect(new Counter()).to.not.equal(new Counter())

      # Making the Counter a singleton
      binder.bind('fixtures/Counter').inSingleton()

      expect(new Counter()).to.equal(new Counter())

    it 'should create a different instance', ->
      class Real
        helloWorld: -> 'hello from real'

      class Wrapper
        constructor: ->
          return new Real()
        helloWorld: -> 'hello from wrapper'

      expect(new Wrapper().helloWorld()).to.equal 'hello from real'

  describe 'instance', ->
    afterEach ->
      binder.clearBindings()

    it 'should return given instance', ->
      expect(new Counter().sayHello()).to.equal 'hello'

      binder.bind('fixtures/Counter').toInstance({
        sayHello: -> 'new hello'
      })

      expect(new Counter().sayHello()).to.equal 'new hello'
