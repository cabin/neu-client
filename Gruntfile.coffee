module.exports = (grunt) ->
  pkg = grunt.file.readJSON('package.json')

  grunt.initConfig
    pkg: pkg
    path:
      app: 'app'
      build: '.tmp'
      components: 'bower_components'
      dist: 'dist'

    clean: ['<%= path.build %>', '<%= path.dist %>']

    sass:
      dist:
        expand: true
        cwd: '<%= path.app %>'
        src: ['css/**/*.{sass,scss}', '!css/**/_*']
        dest: '<%= path.build %>'
        ext: '.css'
      options:
        loadPath: '<%= path.components %>'
    dataUri:
      dist:
        src: ['<%= path.build %>/css/*.css']
        dest: '<%= path.build %>/css'
        options:
          target: ['<%= path.build %>/img/icon/**/*']
    coffee:
      dist:
        expand: true
        cwd: '<%= path.app %>'
        src: 'js/**/*.coffee'
        dest: '<%= path.build %>'
        ext: '.js'
    modernizr:
      devFile: 'remote'
      outputFile: '<%= path.build %>/js/modernizr.js'
      parseFiles: false
      extra:
        load: false
      tests: [
        'forms_placeholder'
        'touch'
      ]
    jinja:
      options:
        contextRoot: '<%= path.app %>/context'
        templateDirs: ['<%= path.app %>/templates']
      dist:
        expand: true
        dest: '<%= path.build %>'
        cwd: '<%= path.app %>/templates'
        src: ['**/!(_)*.html']

    copy:
      build:
        files: [
          {expand: true, src: '<%= path.components %>/**', dest: '<%= path.build %>'}
          {expand: true, cwd: 'app', src: 'css/fonts/**', dest: '<%= path.build %>'}
          {expand: true, cwd: 'app', src: 'img/**', dest: '<%= path.build %>'}
          {expand: true, cwd: 'app', src: 'ie/**', dest: '<%= path.build %>'}
        ]
      dist:
        files: [
          {expand: true, cwd: 'app', src: 'css/fonts/**', dest: '<%= path.dist %>'}
          {expand: true, cwd: 'app', src: 'img/**', dest: '<%= path.dist %>'}
          {expand: true, cwd: 'app', src: 'ie/**', dest: '<%= path.dist %>'}
          {
            expand: true
            cwd: '<%= path.build %>'
            src: ['**/*.html', '!<%= path.components %>/**']
            dest: '<%= path.dist %>'
          }
        ]
    rev:
      src: [
        '<%= path.dist %>/**/*.{css,js}'
        # TODO: find a way to do this without breaking JS-referenced URLs
        #'<%= path.dist %>/img/*.{gif,jpg,jpeg,png}'
        #'<%= path.dist %>/img/team/*.{gif,jpg,jpeg,png}'
        ## TODO: This is to work around the at2x directive not knowing how to
        ## find revved image filenames; may be a better way?
        #'!<%= path.dist %>/img/**/*@2x.*'
        ## Don't rename the Facebook image.
        #'!<%= path.dist %>/img/mark-1500.png'
      ]
    ngmin:
      dist:
        src: '<%= path.dist %>/js/neu.min.js'
        dest: '<%= path.dist %>/js/neu.min.js'
    useminPrepare:
      html: ['<%= path.build %>/**/*.html', '!<%= path.build %>/<%= path.components %>/**']
      options:
        dest: '<%= path.dist %>'
    usemin:
      html: ['<%= path.dist %>/**/*.html']
      css: ['<%= path.dist %>/css/*.css']
      options:
        dirs: ['<%= path.dist %>']
    uglify:
      dist:
        '<%= path.dist %>/js/modernizr.js': '<%= path.build %>/js/modernizr.js'

    connect:
      server:
        options:
          base: '<%= path.build %>'

    watch:
      grunt:
        files: ['Gruntfile.coffee']
      options:
        livereload: true
      sass:
        files: ['app/css/**/*.{sass,scss}']
        tasks: ['sass', 'dataUri']
      coffee:
        files: ['app/js/**/*.coffee']
        tasks: ['coffee', 'karma:unit:run']
      html:
        files: ['app/templates/**/*.html', 'app/context/**/*.js{,on}']
        tasks: ['jinja']
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

  grunt.registerTask('build', [
    'copy:build'
    'jinja'
    'sass'
    'dataUri'
    'coffee'
    'modernizr'
  ])
  grunt.registerTask('test', ['build', 'karma:unitSingle'])
  grunt.registerTask('dist', [
    'clean'
    'build'
    'copy:dist'
    'useminPrepare'
    'concat'
    'cssmin'
    'ngmin'
    'uglify'
    'rev'
    'usemin'
  ])
  grunt.registerTask('dev', ['build', 'connect', 'karma:unit', 'watch'])

  grunt.registerTask('default', ['build'])
