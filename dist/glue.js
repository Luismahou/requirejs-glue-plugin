define(function() {
  var Binder, GlobalScope, annotated, annotationsConfig, binder, checkIfConfigured, checkIfConfiguredAnnotation, checkIfSealed, config, createInstance, globalScope, providerProxy, sealed;
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
  createInstance = function(Clazz, args) {
    var Constructor;
    if (args.length > 0) {
      Constructor = function(args) {
        return Clazz.apply(this, args);
      };
      Constructor.prototype = Clazz.prototype;
      return new Constructor(args);
    } else {
      return new Clazz();
    }
  };
  providerProxy = function(provider) {
    var p;
    if (provider.get && typeof provider.get === 'function') {
      return function() {
        return provider.get();
      };
    } else if (typeof provider === 'function') {
      p = null;
      return function() {
        if (!p) {
          p = new provider();
        }
        return p.get();
      };
    } else {
      throw new Error('Provider must be either a class or an instance and provider "get" method');
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
        to: function(clazz) {
          checkIfConfigured(name);
          config[name] = {
            type: 'c',
            clazz: clazz
          };
          return true;
        },
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
        toProvider: function(provider) {
          if (!provider) {
            throw new Error("provider for " + name + " cannot be null");
          }
          checkIfConfigured(name);
          return config[name] = {
            type: 'p',
            provider: provider,
            providerProxy: providerProxy(provider)
          };
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
            to: function(clazz) {
              if (!clazz) {
                throw new Error("clazz for " + {
                  name: name
                } + " cannot be null");
              }
              annotationsConfig[annotation][name].type = 'c';
              return annotationsConfig[annotation][name].clazz = clazz;
            },
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
      if (instance == null) {
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
          return onload(function() {
            var ac, c, _ref1;
            c = config[name];
            if (!c) {
              c = {};
            }
            if (c.type === 's') {
              if (!c.singleton) {
                c.singleton = new Module();
              }
              return c.singleton;
            } else if (c.type === 'c') {
              return createInstance(c.clazz, arguments);
            } else if (c.type === 'i') {
              return c.instance;
            } else if (c.type === 'g') {
              return globalScope.get(name, Module);
            } else if (c.type === 'p') {
              return c.providerProxy();
            } else if (annotation != null) {
              if (((_ref1 = annotationsConfig[annotation]) != null ? _ref1[name] : void 0) != null) {
                ac = annotationsConfig[annotation][name];
                if (ac.type === 'i') {
                  return annotationsConfig[annotation][name].instance;
                } else if (ac.type === 'c') {
                  return createInstance(ac.clazz, arguments);
                }
              } else {
                if (annotated[annotation] == null) {
                  annotated[annotation] = new Module();
                }
                return annotated[annotation];
              }
            } else {
              return createInstance(Module, arguments);
            }
          });
        });
      }
    }
  };
});
