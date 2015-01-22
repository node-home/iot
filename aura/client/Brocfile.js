var filterCoffeeScript = require('broccoli-coffee')
var uglifyJavaScript = require('broccoli-uglify-js')
var compileStylus = require('broccoli-stylus')
var compileJade = require('broccoli-jade')
var pickFiles = require('broccoli-static-compiler')
var mergeTrees = require('broccoli-merge-trees')
var findBowerTrees = require('broccoli-bower')
var concatenate = require('broccoli-concat')
var env = require('broccoli-env').getEnv()

function preprocess (tree) {
  tree = filterCoffeeScript(tree, {
    bare: true
  })
  tree = compileJade(tree)
  return tree
}

var app = 'app'
app = pickFiles(app, {
  srcDir: '/',
  destDir: 'appkit' // move under appkit namespace
})
app = preprocess(app)

var styles = 'styles'
styles = pickFiles(styles, {
  srcDir: '/',
  destDir: 'appkit'
})
styles = preprocess(styles)

var tests = 'tests'
tests = pickFiles(tests, {
  srcDir: '/',
  destDir: 'appkit/tests'
})
tests = preprocess(tests)

var vendor = 'vendor'

var sourceTrees = [app, styles, vendor]
if (env !== 'production') {
  sourceTrees.push(tests)
}
sourceTrees = sourceTrees.concat(findBowerTrees())

var appAndDependencies = new mergeTrees(sourceTrees, { overwrite: true })
console.log(appAndDependencies);

var appJs = concatenate(appAndDependencies, {
        inputFiles : ['**/*.js'],
        outputFile : '/build/app.js'
    });
var appCss = compileStylus(sourceTrees, 'appkit/app.stylus', 'assets/app.css')

if (env === 'production') {
  appJs = uglifyJavaScript(appJs, {
    // mangle: false,
    // compress: false
  })
}

var publicFiles = 'public'

module.exports = mergeTrees([appJs, appCss, publicFiles])