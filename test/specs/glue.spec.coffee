define (require) ->

  CounterClass = require 'fixtures/Counter'

  binder          = require 'glue!#binder'
  globalScope     = require 'glue!#globalScope'
  Counter         = require 'glue!fixtures/Counter'
  Args            = require 'glue!fixtures/Args'
  CounterProvider = require 'glue!fixtures/CounterProvider'
  Bar             = require 'glue!fixtures/Bar'
  Foo             = require 'glue!fixtures/Foo'
  DepFooProvider  = require 'glue!fixtures/DependentFooProvider'

  # Annotated dependencies
  RedCounter  = require 'glue!fixtures/Counter@red'
  BlueCounter = require 'glue!fixtures/Counter@blue'

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

  describe 'class', ->

    beforeEach ->
      class CustomCounter
        constructor: (args...) ->
          @args = args
          @counter = 0
        incCounter: ->
          @counter++

      binder.bind('fixtures/Counter').to(CustomCounter)

    afterEach ->
      binder.clearBindings()

    it 'should return a new instance of the class', ->
      a = new Counter()
      b = new Counter()
      # They are different instances
      expect(a).to.not.equal(b)

      # If the counter instance has been created properly, it will
      # contain CustomCounter methods and fields
      a.incCounter()
      b.incCounter()
      expect(a.counter).to.equal(b.counter)

    it 'should allow parameters', ->
      a = new Counter('a')
      b = new Counter('b', 'c')

      expect(a.args).to.deep.equal ['a']
      expect(b.args).to.deep.equal ['b', 'c']

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

  describe 'annotations', ->
    afterEach ->
      binder.clearBindings()

    it 'should return different instances for "blue" and "red', ->
      expect(new RedCounter()).to.not.equal(new BlueCounter())

    it 'should return same instance for "red"', ->
      expect(new RedCounter()).to.equal(new RedCounter())

    it 'should return same instance for "blue"', ->
      expect(new BlueCounter()).to.equal(new BlueCounter())

    describe 'binded to instances', ->
      beforeEach ->
        @red  = new Counter()
        @blue = new Counter()
        binder.bind('fixtures/Counter').annotatedWith('red').toInstance @red
        binder.bind('fixtures/Counter').annotatedWith('blue').toInstance @blue

      it 'should return different instances for "blue" and "red', ->
        expect(new RedCounter()).to.not.equal(new BlueCounter())

      it 'should return same instance for "red"', ->
        expect(new RedCounter()).to.equal(new RedCounter())

      it 'should return same instance for "blue"', ->
        expect(new BlueCounter()).to.equal(new BlueCounter())

    describe 'binded to classes', ->
      beforeEach ->
        class Red extends CounterClass
          constructor: (args...) ->
            super()
            @args = args
          whoAmI: ->
            'red'
        class Blue extends CounterClass
          constructor: (args...) ->
            super()
            @args = args
          whoAmI: ->
            'blue'

        binder.bind('fixtures/Counter').annotatedWith('red').to Red
        binder.bind('fixtures/Counter').annotatedWith('blue').to Blue

      it 'should return different instances for "blue" and "red"', ->
        expect(new RedCounter()).to.not.equal(new BlueCounter())
        # Since the annotation is binded to a class every time
        # we call "new" a new instance is created
        expect(new RedCounter()).to.not.equal(new RedCounter())
        expect(new BlueCounter()).to.not.equal(new BlueCounter())

      it 'should return an instance of Red', ->
        expect(new RedCounter().whoAmI()).to.equal 'red'

      it 'should return an instance of Blue', ->
        expect(new BlueCounter().whoAmI()).to.equal 'blue'

      it 'should allow parameters', ->
        red  = new RedCounter('a')
        blue = new BlueCounter('b', 'c')

        expect(red.args).to.deep.equal ['a']
        expect(blue.args).to.deep.equal ['b', 'c']

  describe.only 'providers', ->
    afterEach ->
      binder.clearBindings()

    it 'should invoke provider each time "new" is invoked', ->
      provider = new CounterProvider()

      binder.bind('fixtures/Counter').toProvider provider

      new Counter()
      new Counter()
      expect(provider.invoked).to.equal 2

    it 'should create provider in runtime', ->
      binder.bind('fixtures/Counter').toProvider CounterProvider

      expect(-> new Counter()).to.not.throw

    it 'should allow glue dependencies', ->
      binder.bind('fixtures/Bar').inSingleton()
      binder.bind('fixtures/Foo').toProvider DepFooProvider

      fooOne = new Foo()
      fooTwo = new Foo()

      expect(fooOne).to.not.equal fooTwo
      expect(fooOne.bar).to.equal fooTwo.bar

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
