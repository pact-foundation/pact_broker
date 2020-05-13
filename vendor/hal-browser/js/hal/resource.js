HAL.Models.Resource = Backbone.Model.extend({
  initialize: function(representation) {
    representation = representation || {};
    this.links = representation._links;
    this.title = this.buildTitle(representation); // pact_broker
    this.name = this.buildName(representation); // pact_broker
    if(representation._embedded !== undefined) {
      this.embeddedResources = this.buildEmbeddedResources(representation._embedded);
    }
    this.set(representation);
    this.unset('_embedded', { silent: true });
    this.unset('_links', { silent: true });
  },

  // pact_broker
  buildName: function(representation) {
    return representation.name ||
      (representation._links
        && representation._links.self
        && representation._links.self.name);
  },

  // pact_broker
  buildTitle: function(representation) {
    return representation.title ||
      (representation._links
        && representation._links.self
        && representation._links.self.title);
  },

  buildEmbeddedResources: function(embeddedResources) {
    var result = {};
    _.each(embeddedResources, function(obj, rel) {
      if($.isArray(obj)) {
        var arr = [];
        _.each(obj, function(resource, i) {
          var newResource = new HAL.Models.Resource(resource);
          newResource.identifier = rel + '[' + i + ']';
          newResource.embed_rel = rel;
          arr.push(newResource);
        });
        result[rel] = arr;
      } else {
        var newResource = new HAL.Models.Resource(obj);
        newResource.identifier = rel;
        newResource.embed_rel = rel;
        result[rel] = newResource;
      }
    });
    return result;
  }
});
