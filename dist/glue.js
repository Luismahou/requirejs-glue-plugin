
define(function() {
  var Binder, binder, checkIfConfigured, checkIfSealed, config, registry, sealed;
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
        }
      };
    };

    return Binder;

  })();
  binder = new Binder();
  return {
    load: function(name, req, onload) {
      if (name === 'binder') {
        return onload(binder);
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
