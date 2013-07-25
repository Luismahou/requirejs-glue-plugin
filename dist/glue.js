
define(function() {
  var Binder, GlobalScope, binder, checkIfConfigured, checkIfSealed, config, globalScope, registry, sealed;
  registry = [];
  config = [];
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
  Binder = (function() {

    function Binder() {}

    Binder.prototype.clearBindings = function() {
      checkIfSealed();
      return config = [];
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
          return config[name] = {
            type: 'g'
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
  return {
    load: function(name, req, onload) {
      if (name === '#binder') {
        return onload(binder);
      } else if (name === '#globalScope') {
        return onload(globalScope);
      } else {
        return req([name], function(Module) {
          registry[name] = Module;
          return onload(function() {
            var Constructor, c;
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
