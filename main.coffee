# system-client is what prepares the environment for user apps
# we hook up the postmaster and proxy messages to the OS
# we also provide system packages for the application to use like UI

SystemClient = ->
  # NOTE: These required packages get populated from the parent package when building
  # the runnable app. See util.coffee
  Postmaster = require "postmaster"
  UI = require "ui"

  style = document.createElement "style"
  style.innerHTML = UI.Style.all
  document.head.appendChild style

  postmaster = Postmaster()

  applicationProxy = new Proxy {}
  ,
    get: (target, property, receiver) ->
      target[property] or
      ->
        postmaster.invokeRemote "application", property, arguments...

  systemProxy = new Proxy
    Observable: UI.Observable
    UI: UI
  ,
    get: (target, property, receiver) ->
      target[property] or
      ->
        postmaster.invokeRemote "system", property, arguments...

  # TODO: Also interesting would be to proxy observable arguments where we
  # create the receiver on the opposite end of the membrane and pass messages
  # back and forth like magic

  document.addEventListener "mousedown", ->
    applicationProxy.raiseToTop()
    .catch console.warn

  postmaster.invokeRemote "childLoaded"
  .then (result) ->
    console.log result

    appData = result?.ZineOS

    return appData
  .catch (e) ->
    console.error e
  .then (data) ->
    system: systemProxy
    application: applicationProxy
    postmaster: postmaster

SystemClient.applyExtensions = ->
  require "./lib/extensions"

module.exports = SystemClient
