module.exports = (grunt) ->

  grunt.initConfig
    pkg: grunt.file.readJSON('package.json')

    # Clean
    clean:
      lib:
        src: ['temp/lib']
      test:
        src: ['temp/specs', 'temp/fixtures']

    # Lint
    jshint:
      options:
        curly  : true
        eqeqeq : true
        immed  : true
        latedef: true
        newcap : true
        noarg  : true
        sub    : true
        undef  : true
        boss   : true
        eqnull : true
        globals:
          exports   : true
          module    : false
          define    : false
          describe  : false
          xdescribe : false
          it        : false
          xit       : false
          beforeEach: false
          afterEach : false
          expect    : false
          spyOn     : false

      uses_defaults: [
        'grunt.js'
        'lib/scripts/**/*.js'
        'test/specs/**/*.js'
        'test/fixtures/**/*.js'
      ]

    coffeelint:
      files: [
        'lib/scripts/**/*.coffee'
        'test/specs/**/*.coffee'
        'test/fixtures/**/*.coffee'
      ]

    # Compile
    coffee:
      options:
        bare: true

      lib:
        expand: true
        cwd   : 'lib/scripts'
        src   : ['**/*.coffee']
        dest  : 'temp/lib/scripts'
        ext   : '.js'

      test:
        expand: true
        cwd   : 'test/specs'
        src   : ['**/*.coffee']
        dest  : 'temp/specs'
        ext   : '.spec.js'

      fixtures:
        expand: true
        cwd   : 'test/fixtures'
        src   : ['**/*.coffee']
        dest  : 'temp/fixtures'
        ext   : '.js'

    # Copy
    copy:
      lib:
        files: [
          (
            expand: true
            cwd   : 'lib/scripts/'
            src   : '**/*.!(coffee)'
            dest  : 'temp/lib/scripts/'
          )
        ]

      dist:
        files: [
          (
            expand: true
            cwd   : 'temp/lib/scripts/'
            src   : 'glue.js'
            dest  : 'dist/'
          )
        ]

    # Watch
    # Only watching frequently changed files. When non-frequent changes
    # are made, tasks must be run manually.
    watch:
      code:
        files: ['<%= coffeelint.files %>', '<%= jshint.uses_defaults %>']
        tasks: [
          'jshint', 'coffeelint', 'coffee:lib', 'copy:lib',
          'coffee:test', 'coffee:fixtures', 'test']

    # Tests
    mocha:
      all:
        src    : ['test/**/*.html']
        options:
          bail: true

  # Aliasing 'mocha' task
  grunt.registerTask 'test', 'mocha'

  # Local task to set up lib environment ready for testing
  grunt.registerTask 'lib', [
    'clean:lib', 'jshint', 'coffeelint',
    'copy:lib', 'coffee:lib', 'coffee:test', 'coffee:fixtures']

  # Distribution task
  grunt.registerTask 'dist', ['lib', 'copy:dist']

  # Loading plugins
  grunt.loadNpmTasks 'grunt-contrib'
  grunt.loadNpmTasks 'grunt-coffeelint'
  grunt.loadNpmTasks 'grunt-mocha'
