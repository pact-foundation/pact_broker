# Design pattern for eager loading collections

For collection resources (eg. `/versions` ), associations included in the items (eg. branch versions) must be eager loaded for performance reasons.

The responsiblities of each class used to render a collection resource are as follows:

* collection decorator (eg. `VersionsDecorator`) - delegate each item in the collection to be rendered by the decorator for the individual item, render pagination links
* item decorator (eg. `VersionDecorator`) - render the JSON for each item
* resource (eg. `PactBroker::Api::Resources::Versions`) - coordinate between, and delegate to, the service and the decorator
* service (eg. `PactBroker::Versions::Service`) - just delegate to repository, as there is no business logic required
* repository (eg. `PactBroker::Versions::Repository`) - load the domain objects from the database

If the associations for a model are not eager loaded, then each individual association will be lazy loaded when the decorator for the item calls the association method to render it. This results in at least `<number of items in the collection> * <number of associations to render>` calls to the database, and potentially more if any of the associations have their own associations that are required to render the item. This can cause significant performance issues.

To efficiently render a collection resource, associations must be eager loaded when the collection items are loaded from the database in the repository. Since the repository method for loading the collection may be used in multiple places, and the eager loaded associations required for each of those places may be different (some may not require any associations to be eager loaded), we do not want to hard code the repository to load a fixed set of associations. The list of associations to eager load is therefore passed in to the repository finder method as an argument `eager_load_associations`.

The decorator is the class that knows what associations are going to be called on the model to render the JSON, so following the design guideline of "put things together that change together", the best place for the declaration of "what associations should be eager loaded for this decorator" is in the decorator itself. The `PactBroker::Api::Decorators::BaseDecorator` has a default implementation of this method called `eager_load_associations` which attempts to automatically identify the required associations, but this can be overridden when necessary.

We can therefore add the following responsiblities to our previous list:

* item decorator - return a list of all the associations (including nested associations) that should be eager loaded in order to render its item
* repository - eager load the associations that have been passed into it
* resource - pass in the eager load associations to the repository from the decorator
