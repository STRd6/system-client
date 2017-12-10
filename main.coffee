# system-client is what prepares the environment for user apps
# we hook up the postmaster and proxy messages to the OS
# we also provide system packages for the application to use like UI

{version} = require "./pixie"

Postmaster = require "postmaster"
{Observable} = UI = require "ui"

SystemClient = (appDelegate) ->
  style = document.createElement "style"
  style.innerHTML = UI.Style.all
  document.head.appendChild style

  externalObservables = {}

  postmaster = Postmaster()
  # For receiving messages from the system
  postmaster.delegate =
    application: (method, args...) ->
      appDelegate(method, args...)
    updateSignal: (name, newValue) ->
      externalObservables[name](newValue)

  remoteExists = postmaster.remoteTarget()

  # For sending messages to the system
  applicationProxy = new Proxy
    observeSignal: (name, handler) ->
      observable = Observable()
      externalObservables[name] = observable

      observable.observe handler

      # Invoke the handler with the initial value
      postmaster.invokeRemote "application", "observeSignal", name
      .then handler
  ,
    get: (target, property, receiver) ->
      target[property] or
      ->
        postmaster.invokeRemote "application", property, arguments...

  systemProxy = new Proxy
    ready: ->
      if remoteExists
        postmaster.invokeRemote "ready",
          ZineOSClient: version
        .then (result) ->
          console.log result
          appData = result?.ZineOS

          if appData
            initializeOnZineOS()

          return appData
      else # Quick fail when there is no parent window to connect to
        Promise.reject "No parent window"
  ,
    get: (target, property, receiver) ->
      target[property] or
      ->
        postmaster.invokeRemote "system", property, arguments...

  # TODO: Also interesting would be to proxy observable arguments where we
  # create the receiver on the opposite end of the membrane and pass messages
  # back and forth like magic

  initializeOnZineOS = ->
    document.addEventListener "mousedown", ->
      applicationProxy.raiseToTop()
      .catch console.warn

  system: systemProxy
  application: applicationProxy
  postmaster: postmaster
  util:
    FileIO: require("./lib/file-io")(systemProxy)
  Drop: require "./lib/drop"
  Observable: UI.Observable
  UI: UI
  version: version

SystemClient.applyExtensions = ->
  require "./lib/extensions"

Object.assign SystemClient,
  Observable: UI.Observable
  UI: UI

module.exports = SystemClient
