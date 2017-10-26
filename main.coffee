# system-client is what prepares the environment for user apps
# we hook up the postmaster and proxy messages to the OS
# we also provide system packages for the application to use like UI

{version} = require "./pixie"

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
    ready: ->
      postmaster.invokeRemote "ready",
        ZineOSClient: version
      .then (result) ->
        console.log result
        appData = result?.ZineOS

        return appData
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

  system: systemProxy
  application: applicationProxy
  postmaster: postmaster
  util:
    FileIO: require "./lib/file-io"
  Observable: UI.Observable
  UI: UI
  version: version

SystemClient.applyExtensions = ->
  require "./lib/extensions"

module.exports = SystemClient
