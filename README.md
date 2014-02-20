[![Build Status](https://travis-ci.org/Luismahou/requirejs-glue-plugin.png)](https://travis-ci.org/Luismahou/requirejs-glue-plugin)
[![Dependency Status](https://david-dm.org/luismahou/requirejs-glue-plugin.png)](https://david-dm.org/luismahou/requirejs-glue-plugin)
[![devDependency Status](https://david-dm.org/luismahou/requirejs-glue-plugin/dev-status.png)](https://david-dm.org/luismahou/requirejs-glue-plugin#info=devDependencies)

### Introduction

As a Java guy, one of the things that I missed more when I switch to Javascript was [Google Guice](code.google.com/p/google-guice/).

**GlueJs** is an attempt to fill that gap in combination with [RequireJS](requirejs.org).

**GlueJs** is implemented as a RequireJS plugin.

### Learn by example

RequireJS configuration:
```javascript
requirejs.config({
    paths: {
        glue: '/path/to/require/glue/plugin'
    }
});
```

**GlueJs** populates the ```binder```. The binder allows you to bind RequireJS paths.

```javascript
// Gets the binder. Note that the module name starts with '#'. The hash is used to distinguish between normal modules and GlueJS ones
var binder = require('glue!#binder');
```

You can bind ```Foo``` into the singleton scope. 
```javascript
binder.bind('Foo').inSingleton();

// Every time that require('glue!Foo') is executed, it will return the same instance
```

Or to an instance:
```javascript
var foo = createFoo();
binder.bind('Foo').toInstance(foo);

// require('glue!Foo') will return "foo"
```

You can also annotate modules:
```javascript
binder.bind('Foo').annotatedWith('red').toInstance(redFoo);
binder.bind('Foo').annotatedWith('blue').toInstance(blueFoo);

// require('glue!Foo@red') will return "redFoo" while require('glue!Foo@blue') will return "blueFoo"
```

### Constraints

Modules loaded via **GlueJS** must ALWAYS return a class. The *magic* happens when you try to create an instance of the module:
```javascript
define(function(require) {
    var Foo = require('glue!Foo');

    var Bar = function() {
        // When "new" is executed GlueJS determines how to instantiate "Foo"
        var foo = new Foo();
    };

    return Bar;
});
```

### Is Dependency Injection really necessary in a language like Javascript?

IMHO is not as important as in Java. You can definitely write a successful app without it. Besides, RequireJS brings some similar features, for example, you can convert ```Foo``` into a singleton by simply:
```javascript
define(function(require) {
    var Foo = function() {
        // ...
    };
    var singleton = new Foo()
    // require('Foo') will always return a reference to 'singleton'
    return singleton;
});
```

The problem arises when you try to test your code. If ```Foo``` stores state, you'll need to clean it after every test to ensure that you're not leaking that state from one test to another. For example:

```javascript
// Counter definition
define(function(require) {
    var Counter = function() {
        this.counter = 0;
    };
    Counter.prototype.increment = function() {
        this.counter++;
    };
    Counter.prototype.decrement = function() {
        this.counter--;
    };
    Counter.prototype.getCounter = function() {
        return this.counter;
    };

    // Returning a singleton
    return new Counter();
});

// In a test file
define(function(require) {
    var counter = require('counter');

    describe('Counter', function() {
        it('should increment counter by one', function() {
            counter.increment();
            expect(counter.getCounter()).to.equal(1);
        });
        it('should decrement counter by one', function() {
            counter.decrement();
            // It will fail, because the counter was modified in the previous test.
            expect(counter.getCounter()).to.equal(-1);
        });
    });
});
```

With **GlueJS** the test would look like:
```javascript
// Counter definition
define(function(require) {
    var Counter = function() {
        this.counter = 0;
    };
    Counter.prototype.increment = function() {
        this.counter++;
    };
    Counter.prototype.decrement = function() {
        this.counter--;
    };
    Counter.prototype.getCounter = function() {
        return this.counter;
    };

    // Returning the class
    return Counter();
});

// In a test file
define(function(require) {
    var binder  = require('glue!#binder');
    var Counter = require('glue!Counter');

    describe('Counter', function() {
        beforeEach(function() {
            binder.bind('Counter').inSingleton();

            this.counter = new Counter();
        });
        afterEach(function() {
            // Utility method that removes all the references to objects
            // instantiated by GlueJS
            binder.clearBindings();
        });
        it('should increment counter by one', function() {
            this.counter.increment();
            expect(this.counter.getCounter()).to.equal(1);
        });
        it('should decrement counter by one', function() {
            this.counter.decrement();
            // Now, this test will pass, because the singleton instance is re-instantiated from test to test.
            expect(this.counter.getCounter()).to.equal(-1);
        });
    });
});
```
