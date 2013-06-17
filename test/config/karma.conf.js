basePath = '../../';

files = [
  JASMINE,
  JASMINE_ADAPTER,
  'app/bower_components/angular/angular.js',
  'app/bower_components/angular-mocks/angular-mocks.js',
  'app/build/js/**/*.js',
  'test/unit/**/*.coffee'
];

autoWatch = true;

browsers = ['Chrome'];

junitReporter = {
  outputFile: 'test_out/unit.xml',
  suite: 'unit'
};
