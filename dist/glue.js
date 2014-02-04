
define(function() {
  var Binder, GlobalScope, annotated, annotationsConfig, binder, checkIfConfigured, checkIfConfiguredAnnotation, checkIfSealed, config, globalScope, registry, sealed;
  registry = [];
  config = [];
  annotationsConfig = [];
  sealed = false;
  checkIfSealed = function() {
    if (sealed) {
      throw new Error('Binder is sealed. Bindings cannot be modified.');
    }
  };
  checkIfConfigured = function(name) {
    if (config[name]) {
      throw new Error("" + name + " is already configured");
    }
  };
  checkIfConfiguredAnnotation = function(name, annotation) {
    var _ref;
    if (((_ref = annotationsConfig[annotation]) != null ? _ref[name] : void 0) === name) {
      throw new Error("" + name + " is already annotated with " + annotation);
    }
  };
  Binder = (function() {

    function Binder() {}

    Binder.prototype.clearBindings = function() {
      checkIfSealed();
      config = [];
      return annotationsConfig = [];
    };

    Binder.prototype.seal = function() {
      return sealed = true;
    };

    Binder.prototype.bind = function(name) {
      checkIfSealed();
      return {
        toInstance: function(instance) {
          if (!instance) {
            throw new Error("instance for " + name + " cannot be null");
          }
          checkIfConfigured(name);
          config[name] = {
            type: 'i',
            instance: instance
          };
          return true;
        },
        inSingleton: function() {
          checkIfConfigured(name);
          config[name] = {
            type: 's'
          };
          return true;
        },
        inGlobal: function() {
          checkIfConfigured(name);
          config[name] = {
            type: 'g'
          };
          return true;
        },
        annotatedWith: function(annotation) {
          checkIfConfiguredAnnotation(name, annotation);
          annotationsConfig[annotation] = {};
          annotationsConfig[annotation][name] = {};
          return {
            toInstance: function(instance) {
              if (!instance) {
                throw new Error("instance for " + name + " cannot be null");
              }
              annotationsConfig[annotation][name].type = 'i';
              return annotationsConfig[annotation][name].instance = instance;
            }
          };
        }
      };
    };

    return Binder;

  })();
  GlobalScope = (function() {

    function GlobalScope() {
      this.globalInstances = {};
      this.started = false;
    }

    GlobalScope.prototype.start = function() {
      return this.started = true;
    };

    GlobalScope.prototype.stop = function() {
      this.globalInstances = {};
      return this.started = false;
    };

    GlobalScope.prototype.get = function(name, Module) {
      var instance;
      if (!this.started) {
        throw new Error('Global scope is not started');
      }
      instance = this.globalInstances[name];
      if (!(instance != null)) {
        instance = new Module();
        this.globalInstances[name] = instance;
      }
      return instance;
    };

    return GlobalScope;

  })();
  binder = new Binder();
  globalScope = new GlobalScope();
  annotated = {};
  return {
    load: function(name, req, onload) {
      var annotation, _ref;
      if (name === '#binder') {
        return onload(binder);
      } else if (name === '#globalScope') {
        return onload(globalScope);
      } else {
        _ref = name.split('@'), name = _ref[0], annotation = _ref[1];
        return req([name], function(Module) {
          registry[name] = Module;
          return onload(function() {
            var Constructor, c, _ref1;
            c = config[name];
            if (!c) {
              c = {};
            }
            if (c.type === 's') {
              if (!c.singleton) {
                c.singleton = new Module();
              }
              return c.singleton;
            } else if (c.type === 'i') {
              return c.instance;
            } else if (c.type === 'g') {
              return globalScope.get(name, Module);
            } else if (annotation != null) {
              if (((_ref1 = annotationsConfig[annotation]) != null ? _ref1[name] : void 0) != null) {
                return annotationsConfig[annotation][name].instance;
              } else {
                if (!(annotated[annotation] != null)) {
                  annotated[annotation] = new Module();
                }
                return annotated[annotation];
              }
            } else {
              if (arguments.length > 0) {
                Constructor = function(args) {
                  return Module.apply(this, args);
                };
                Constructor.prototype = Module.prototype;
                return new Constructor(arguments);
              } else {
                return new Module();
              }
            }
          });
        });
      }
    }
  };
});
