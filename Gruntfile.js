'use strict';

module.exports = function (grunt) {

  // Project configuration.
  grunt.initConfig({
    nodeunit: {
      files: ['test/**/*_test.js']
    },
    coffee: {
//         compile: {
//            files: {
//               'scripts/import-squishle.js': 'scripts/import-squishle.coffee',
//               'lib/pegg=parse.js': 'lib/pegg-parse.coffee'
//            }
//         },
      glob_to_multiple: {
        expand: true,
        flatten: true,
        cwd: './',
        src: ['lib/*.coffee', 'scripts/*.coffee'],
        dest: './run/',
        ext: '.js'
      }
    },
    jshint: {
      options: {
        jshintrc: '.jshintrc'
      },
      gruntfile: {
        src: 'Gruntfile.js'
      },
      lib: {
        src: ['lib/**/*.js']
      },
      test: {
        src: ['test/**/*.js']
      }
    },
    watch: {
      scripts: {
        files: '<%= coffee.glob_to_multiple.src %>',
        tasks: ['coffee:glob_to_multiple']
      },
      gruntfile: {
        files: '<%= jshint.gruntfile.src %>',
        tasks: ['jshint:gruntfile']
      },
      lib: {
        files: '<%= jshint.lib.src %>',
        tasks: ['jshint:lib', 'nodeunit']
      },
      test: {
        files: '<%= jshint.test.src %>',
        tasks: ['jshint:test', 'nodeunit']
      }
    }
  });

  // These plugins provide necessary tasks.
  grunt.loadNpmTasks('grunt-contrib-nodeunit');
  grunt.loadNpmTasks('grunt-contrib-jshint');
  grunt.loadNpmTasks('grunt-contrib-watch');
  grunt.loadNpmTasks('grunt-contrib-coffee');

  // Default task.
  grunt.registerTask('default', ['jshint', 'nodeunit']);

};
