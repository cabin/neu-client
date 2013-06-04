module.exports = (grunt) ->
  pkg = grunt.file.readJSON('package.json')

  grunt.initConfig
    pkg: pkg

  # Load tasks from all required grunt plugins.
  for dep of pkg.devDependencies when dep.indexOf('grunt-') is 0
    grunt.loadNpmTasks(dep)

  grunt.registerTask('default', ['build'])
  grunt.registerTask('build', ['bowerful', 'coffee'])
  grunt.registerTask('test', ['build', 'karma'])
  grunt.registerTask('deploy', ['build', 'uglify'])
