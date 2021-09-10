$(document).ready(function() {
  $(".pact-badge").click(function() {
    $(".pact-badge-markdown").toggle();
  });

  $(".more-options")
    .materialMenu("init", {
      position: "overlay",
      animationSpeed: 1,
      items: [
        {
          type: "normal",
          text: "View in API Browser",
          click: function(openMenuElement) {
            window.location.href = openMenuElement.data().apiBrowserUrl;
          }
        },
        {
          type: "normal",
          text: "View Matrix",
          click: function(openMenuElement) {
            window.location.href = openMenuElement.data().matrixUrl;
          }
        },
        {
          type: "normal",
          text: "Delete ...",
          click: function(openMenuElement) {
            promptToDeleteResource(
              openMenuElement.data().pactUrl,
              createDeletionConfirmationText(openMenuElement.data())
            );
          }
        }
      ]
    })
    .click(function() {
      $(this).materialMenu("open");
    });
});

function h(string) {
  return jQuery('<div/>').text(string).html();
}

function createDeletionConfirmationText(data) {
  return `Do you wish to delete the pact for version ${
    h(data.consumerVersionNumber)
  } of ${h(data.consumerName)}?`;
}

function confirmDeleteResource(
  confirmationText,
  confirmCallback,
  cancelCallback
) {
  $.confirm({
    title: "Confirm!",
    content: confirmationText,
    buttons: {
      delete: {
        text: "DELETE",
        btnClass: "alert alert-danger",
        keys: ["enter", "shift"],
        action: confirmCallback
      },
      cancel: cancelCallback
    }
  });
}

function promptToDeleteResource(deletionUrl, confirmationText) {
  const cancelled = function() {};
  const confirmed = function() {
    deleteResource(deletionUrl, handleDeletionSuccess, handleDeletionFailure);
  };

  confirmDeleteResource(confirmationText, confirmed, cancelled);
}

function createWhereToNextConfirmationConfiguration(latestPactUrl, indexUrl) {
  return {
    title: "Pact deleted",
    content: "Where to next?",
    buttons: {
      latest: {
        text: "Latest pact",
        keys: ["enter", "shift"],
        action: function() {
          window.location.href = latestPactUrl;
        }
      },
      home: {
        text: "Home",
        action: function() {
          window.location.href = indexUrl;
        }
      }
    }
  };
}

function createAllPactsDeletedConfirmationConfiguration(indexUrl) {
  return {
    title: "Pact deleted",
    content: "All versions of this pact have now been deleted.",
    buttons: {
      home: {
        text: "Home",
        action: function() {
          window.location.href = indexUrl;
        }
      }
    }
  };
}

function handleDeletionSuccess(responseBody) {
  if (responseBody._links["pb:latest-pact-version"]) {
    $.confirm(
      createWhereToNextConfirmationConfiguration(
        responseBody._links["pb:latest-pact-version"].href,
        responseBody._links["index"].href
      )
    );
  } else {
    $.confirm(createAllPactsDeletedConfirmationConfiguration(responseBody._links["index"].href));
  }
}

function createErrorMessage(responseBody) {
  if (responseBody && responseBody.error && responseBody.error.message && responseBody.error.reference) {
    return `<p>Could not delete resources due to error: ${
      responseBody.error.message
    }</p><p>Error reference:
      ${responseBody.error.reference}
      </p>`;
  } else if (responseBody) {
    return `Could not delete resources due to error: ${JSON.stringify(responseBody)}`;
  }

  return "Could not delete resources.";
}

function handleDeletionFailure(response) {
  $.alert({
    title: "Error",
    content: createErrorMessage(response)
  });
}

function deleteResource(url, successCallback, errorCallback) {
  $.ajax({
    url: url,
    dataType: "json",
    type: "delete",
    accepts: {
      text: "application/hal+json"
    },
    success: function(data, textStatus, jQxhr) {
      successCallback(data);
    },
    error: function(jqXhr, textStatus, errorThrown) {
      errorCallback(jqXhr.responseJSON);
    }
  });
}
