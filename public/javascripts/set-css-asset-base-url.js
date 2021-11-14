/*
  Set the base URL of the background images
  so they load from the right path when the base
  URL of the app is not /
  Must be loaded after the css but before any of the elements have started to render.
*/

function setCssAssetBaseUrl(base_url, varName) {
  const urlVar = getComputedStyle(document.documentElement).getPropertyValue(varName)
  if (urlVar) {
    const absoluteUrlVar = urlVar.replace(/\//, (base_url + '/'));
    const root = document.querySelector(':root');
    root.style.setProperty(varName, absoluteUrlVar);
  }
}

setCssAssetBaseUrl(BASE_URL, '--kebab-url');
setCssAssetBaseUrl(BASE_URL, '--pact-kebab-url');
setCssAssetBaseUrl(BASE_URL, '--clock-url');
setCssAssetBaseUrl(BASE_URL, '--arrow-switch-url');
setCssAssetBaseUrl(BASE_URL, '--alert-url');
setCssAssetBaseUrl(BASE_URL, '--copy-url');
setCssAssetBaseUrl(BASE_URL, '--check-url');
