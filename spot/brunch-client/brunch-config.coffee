exports.config =
  # See http://brunch.io/#documentation for docs.
  files:
    javascripts:
      joinTo:
        'app.js': /^app/
        'vendor.js': /^(bower_components|vendor)/
    stylesheets:
      joinTo:
        'app.css': /^(app|vendor|bower_components)/
    templates:
      joinTo:
        'index.html' : /^app/
  plugins:
    on: ['jade', 'coffeescript', 'stylus']
    jade:
      pretty: yes     # Adds pretty-indentation whitespaces to output (false by default)

    # static_jade:                        # all optionals
    #   extension:  ".static.jade"        # static-compile each file with this extension in `assets`
    #   path:       [ /app(\/|\\)docs/ ]  # static-compile each file in this directories
    #   asset:      "app/jade_asset"      # specify the compilation output
