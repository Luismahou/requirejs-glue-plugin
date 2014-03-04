# I consider GlueJS a distant cousin of Google Guice.
# It fills some gaps that requirejs doesn't (as it is not intended to).
# These are the following scenarios fixed by GlueJS:
# - Singletons: the idea of singletons is good, but implementations sucks.
#   GlueJS allows you to ensure that only one instance of a module is created.
# - Mock modules for testing: If module 'A' creates an instance of module 'B',
#   how do you ensure that 'b' is a mock instead of a real instance of 'B'?
#   You can't. GlueJS allows us you change at runtime a real module for a mock.
define  ->

  # Contains bindings for modules
  config            = []
  # Contains bindings for annotated modules
  annotationsConfig = []
  # Indicates whether the bindings can be modified or not
  sealed            = false

  checkIfSealed = ->
    if sealed
      throw new Error 'Binder is sealed. Bindings cannot be modified.'
  checkIfConfigured = (name) ->
    if config[name]
      throw new Error "#{name} is already configured"

  checkIfConfiguredAnnotation = (name, annotation) ->
    if annotationsConfig[annotation]?[name] is name
      throw new Error "#{name} is already annotated with #{annotation}"

  createInstance = (Clazz, args) ->
    # Default behaviour: create a new instance
    if args.length > 0
      Constructor = (args) ->
        Clazz.apply @, args

      Constructor.prototype = Clazz.prototype
      new Constructor args
    else
      new Clazz()

  # Configures bindings for your modules
  class Binder
    clearBindings: ->
      checkIfSealed()
      config = []
      annotationsConfig = []

    seal: ->
      sealed = true

    # Starting point to bind a module
    bind: (name) ->
      checkIfSealed()

      {
        # binds the module name to a factory function
        to: (clazz) ->
          checkIfConfigured(name)
          config[name] =
            type : 'c'
            clazz: clazz

          # Otherwise coffeescript would return the private config
          true
        # binds the module name to the given instance
        toInstance: (instance) ->
          if not instance
            throw new Error "instance for #{name} cannot be null"
          checkIfConfigured(name)
          config[name] =
            type    : 'i'
            instance: instance

          # Otherwise coffeescript would return the private config
          true
        ,
        # binds the module name as a singleton
        inSingleton: ->
          checkIfConfigured(name)
          config[name] =
            type: 's'

          # Otherwise coffeescript would return the private config
          true
        ,
        # binds the module in the global scope
        inGlobal: ->
          checkIfConfigured name
          config[name] =
            type: 'g'

          # Otherwise coffeescript would return the private config
          true
        ,
        # binds the module with an specific annotation
        annotatedWith: (annotation) ->
          checkIfConfiguredAnnotation name, annotation
          annotationsConfig[annotation] = {}
          annotationsConfig[annotation][name] = {}

          {
            to: (clazz) ->
              if not clazz
                throw new Error "clazz for #{{name}} cannot be null"
              annotationsConfig[annotation][name].type = 'c'
              annotationsConfig[annotation][name].clazz = clazz
            toInstance: (instance) ->
              if not instance
                throw new Error "instance for #{name} cannot be null"
              annotationsConfig[annotation][name].type = 'i'
              annotationsConfig[annotation][name].instance = instance
          }
      }

  class GlobalScope
    constructor: ->
      @globalInstances = {}
      @started = false

    start: ->
      @started = true

    stop: ->
      @globalInstances = {}
      @started = false

    get: (name, Module) ->
      if not @started
        throw new Error 'Global scope is not started'
      instance = @globalInstances[name]
      if not instance?
        instance = new Module()
        @globalInstances[name] = instance

      instance

  # One instance is enough for now...
  binder      = new Binder()
  globalScope = new GlobalScope()
  annotated   = {}

  {
    # requirejs load method. It loads the module according to its bindings.
    load: (name, req, onload) ->
      # 'binder' is reserved for our binder object.
      if name is '#binder'
        onload binder
      else if name is '#globalScope'
        onload globalScope
      else
        # Checking if module is annotated
        # atIndex = name.indexOf '@'
        [name, annotation] = name.split '@'

        # Loading the real module
        req([name], (Module) ->

          # Invoking the requirejs callback passing a function
          # that modifies at runtime the module instance according
          # to its bindings
          onload ->
            c = config[name]
            c = {} if not c
            if c.type is 's' # Is a singleton
              c.singleton = new Module() if not c.singleton

              c.singleton
            else if c.type is 'c' # Is a factory method
              createInstance(c.clazz, arguments)
            else if c.type is 'i' # Is an instance
              c.instance
            else if c.type is 'g' # Is in global context
              globalScope.get name, Module
            else if annotation?
              # Checking if we have configuration for this annotation
              if annotationsConfig[annotation]?[name]?
                ac = annotationsConfig[annotation][name]
                if ac.type is 'i'
                  annotationsConfig[annotation][name].instance
                else if ac.type is 'c'
                  createInstance(ac.clazz, arguments)

              # Then, default behaviour: Creating a new instance per annotation
              else
                if not annotated[annotation]?
                  annotated[annotation] = new Module()
                annotated[annotation]
            else
              createInstance(Module, arguments)
        )
  }