define (require) ->

  binder      = require 'glue!#binder'
  globalScope = require 'glue!#globalScope'
  Counter     = require 'glue!fixtures/Counter'
  Args        = require 'glue!fixtures/Args'

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

  describe 'global scope', ->
    beforeEach ->
      binder.bind('fixtures/Counter').inGlobal()

    afterEach ->
      binder.clearBindings()

    it 'should throw error if not started', ->
      expect(-> new Counter()).to.throw()

    it 'should throw error if stopped', ->
      globalScope.start()
      globalScope.stop()
      expect(-> new Counter()).to.throw()

    it 'should return same instance while is same global scope', ->
      globalScope.start()
      expect(new Counter()).to.equal(new Counter())
      globalScope.stop()

    it 'should return different instance when in different global scope', ->
      globalScope.start()
      firstCounter = new Counter()
      globalScope.stop()
      # Starting scope again
      globalScope.start()
      # This Counter instance has been created in a different global scope
      expect(new Counter()).to.not.equal(firstCounter)
      globalScope.stop()

  describe 'default', ->
    afterEach ->
      binder.clearBindings()

    it 'should return a new instance each time', ->
      expect(new Counter()).to.not.equal(new Counter())

    it 'should create instance with arguments', ->
      argsOne = new Args '1', '2'
      argsTwo = new Args '3', '4'

      expect(argsOne.argOne).to.equal '1'
      expect(argsOne.argTwo).to.equal '2'
      expect(argsTwo.argOne).to.equal '3'
      expect(argsTwo.argTwo).to.equal '4'

  describe 'clearBindings', ->
    it 'clears singletons', ->
      binder.bind('fixtures/Counter').inSingleton()

      firstCounter = new Counter()

      binder.clearBindings()

      binder.bind('fixtures/Counter').inSingleton()

      expect(firstCounter).to.not.equal(new Counter())
