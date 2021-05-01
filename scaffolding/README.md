# Scaffolding

Generates a new model class and its associated:

 * migration
 * resource
 * decorator (todo)
 * service (todo)
 * repository (todo)
 * resource spec (todo)
 * decorator spec (todo)
 * service spec (todo)
 * repository spec (todo)

## Usage

Set `MODEL_CLASS_FULL_NAME` to the full name of the class, and run:

 ```
bundle exec ruby scaffolding/run.rb
 ```

Note that the class name must be in the format X::Y::Z (a class nested inside two modules).
