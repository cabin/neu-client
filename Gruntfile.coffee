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
          angular: '1.0.7'
          'angular-mocks': '1.0.7'

    clean: ['<%= path.build %>', '<%= path.dist %>']

    coffee:
      dist:
        expand: true
        cwd: 'app'
        src: 'js/**/*.coffee'
        dest: '<%= path.build %>'
        ext: '.js'

    uglify:
      '<%= path.dist %>/js/neu.min.js': ['<%= path.build %>/js/**/*.js']
      '<%= path.dist %>/js/vendor.min.js': [
        '<%= path.components %>/angular/angular.js'
      ]
    rev:
      src: ['<%= path.dist %>/**/*.js']

    copy:
      '<%= path.dist %>/index.html': 'app/index.html'

    useminPrepare:
      html: '<%= path.dist %>/index.html'
    usemin:
      html: ['<%= path.dist %>/index.html']

    watch:
      grunt:
        files: ['Gruntfile.coffee']
      options:
        livereload: true
        nospawn: true
      coffee:
        files: ['app/js/**/*.coffee']
        tasks: ['coffee']
      karma:
        files: ['app/js/**/*.js', 'test/unit/**/*.coffee']


  # Load tasks from all required grunt plugins.
  for dep of pkg.devDependencies when dep.indexOf('grunt-') is 0
    grunt.loadNpmTasks(dep)

  grunt.registerTask('build', ['coffee'])
  grunt.registerTask('test', ['build', 'karma'])
  grunt.registerTask('dist', [
    'clean'
    'useminPrepare'
    'build'
    'uglify'
    'copy'
    'rev'
    'usemin'
  ])

  grunt.registerTask('default', ['build'])
