basePath = '../../';

files = [
  JASMINE,
  JASMINE_ADAPTER,
  'bower_components/angular-1.1.x/angular.js',
  'bower_components/angular-1.1.x/angular-mocks.js',
  '.tmp/js/**/*.js',
  'test/unit/**/*.coffee'
];

autoWatch = true;

browsers = ['Chrome', 'Firefox'];

junitReporter = {
  outputFile: 'test_out/unit.xml',
  suite: 'unit'
};
