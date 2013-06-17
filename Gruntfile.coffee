module.exports = (grunt) ->
  pkg = grunt.file.readJSON('package.json')

  grunt.initConfig
    pkg: pkg
    path:
      build: 'app/build'
      components: 'app/bower_components'
      dist: 'dist'

    bowerful:
      dist:
        store: '<%= path.components %>'
        packages:
          'angular-1.1.x': '1.1.5'
          'bourbon': '3.1.6'
          'normalize-css': '2.1.2'

    clean: ['<%= path.build %>', '<%= path.dist %>']

    sass:
      dist:
        expand: true
        cwd: 'app'
        src: ['css/**/*.{sass,scss}', '!css/**/_*']
        dest: '<%= path.build %>'
        ext: '.css'
      options:
        loadPath: '<%= path.components %>'
    coffee:
      dist:
        expand: true
        cwd: 'app'
        src: 'js/**/*.coffee'
        dest: '<%= path.build %>'
        ext: '.js'

    cssmin:
      '<%= path.dist %>/css/neu.min.css': [
        '<%= path.components %>/normalize-css/normalize.css'
        '<%= path.build %>/css/**/*.css'
      ]
    uglify:
      '<%= path.dist %>/js/neu.min.js': ['<%= path.build %>/js/**/*.js']
      '<%= path.dist %>/js/vendor.min.js': [
        '<%= path.components %>/AngularJS/angular.js'
      ]

    copy:
      '<%= path.dist %>/index.html': 'app/index.html'
    rev:
      src: ['<%= path.dist %>/**/*.{css,js}']
    useminPrepare:
      html: '<%= path.dist %>/index.html'
    usemin:
      html: ['<%= path.dist %>/index.html']

    connect:
      server:
        options:
          base: 'app'

    watch:
      grunt:
        files: ['Gruntfile.coffee']
      options:
        livereload: true
        nospawn: true
      sass:
        files: ['app/css/**/*.{sass,scss}']
        tasks: ['sass']
      coffee:
        files: ['app/js/**/*.coffee']
        tasks: ['coffee', 'karma:unit:run']
      html:
        files: ['app/**/*.html']
        livereload: true
      karma:
        files: ['test/unit/**/*.coffee']
        tasks: ['karma:unit:run']

    karma:
      unit:
        configFile: 'test/config/karma.conf.js'
        background: true
        browsers: ['PhantomJS']
      unitSingle:
        configFile: 'test/config/karma.conf.js'
        singleRun: true


  # Load tasks from all required grunt plugins.
  for dep of pkg.devDependencies when dep.indexOf('grunt-') is 0
    grunt.loadNpmTasks(dep)

  grunt.registerTask('build', ['sass', 'coffee'])
  grunt.registerTask('test', ['build', 'karma:unitSingle'])
  grunt.registerTask('dist', [
    'clean'
    'useminPrepare'
    'build'
    'cssmin'
    'uglify'
    'copy'
    'rev'
    'usemin'
  ])
  grunt.registerTask('dev', ['build', 'connect', 'karma:unit', 'watch'])

  grunt.registerTask('default', ['build'])
