# system-client is what prepares the environment for user apps
# we hook up the postmaster and proxy messages to the OS
# we also provide system packages for the application to use like UI

{version} = require "./pixie"

Postmaster = require "postmaster"
{Observable} = UI = require "ui"

SystemClient = (opts={}) ->
  if opts.applyStyle
    style = document.createElement "style"
    style.innerHTML = UI.Style.all
    document.head.appendChild style

  externalObservables = {}

  # Queue up messages until a delegate is assigned
  heldApplicationMessages = []

  postmaster = Postmaster()
  # For receiving messages from the system
  postmaster.delegate =
    application: (method, args...) ->
      if applicationTarget.delegate
        applicationTarget.delegate[method](args...)
      else
        # This promise should keep the channel unresolved until the future
        new Promise (resolve, reject) ->
          heldApplicationMessages.push (delegate) ->
            try
              resolve delegate[method](args...)
            catch e
              reject e

    updateSignal: (name, newValue) ->
      externalObservables[name](newValue)

    fn: (handlerId, args) ->
      # TODO: `this` is null but should be `system` here for bound events.
      eventListeners[handlerId].apply(null, args)

  remoteExists = postmaster.remoteTarget()

  applicationTarget =
    observeSignal: (name, handler) ->
      observable = Observable()
      externalObservables[name] = observable

      observable.observe handler

      # Invoke the handler with the initial value
      postmaster.invokeRemote "application", "observeSignal", name
      .then handler

  # For sending messages to the system
  applicationProxy = new Proxy applicationTarget,
    get: (target, property, receiver) ->
      target[property] or
      ->
        postmaster.invokeRemote "application", property, arguments...
    set: (target, property, value, receiver) ->
      if property is "delegate"
        heldApplicationMessages.forEach (fn)->
          fn(value)

        heldApplicationMessages = []

      target[property] = value

      return target[property]

  lastEventListenerId = 0
  eventListeners = {}
  readyPromise = null
  systemTarget =
    ready: ->
      return readyPromise if readyPromise

      if remoteExists
        readyPromise = postmaster.invokeRemote "ready",
          ZineOSClient: version
        .then (result) ->
          console.log result
          appData = result?.ZineOS

          if appData
            initializeOnZineOS(appData)

          return appData
      else # Quick fail when there is no parent window to connect to
        polyfillForStandalone()

        readyPromise = Promise.reject "No parent window"

    # Bind listeners to system events, sending an id in place of a local function
    # reference
    on: (eventName, handler) ->
      lastEventListenerId += 1

      eventListeners[lastEventListenerId] = handler
      postmaster.invokeRemote "system", "on", eventName, lastEventListenerId

    off: (eventName, handler) ->
      [handlerId] = Object.keys(eventListeners).filter (id) ->
        eventListeners[id] is handler

      delete eventListeners[handlerId]
      postmaster.invokeRemote "system", "off", eventName, handlerId

  # Unattached
  polyfillForStandalone = ->
    Object.assign systemTarget,
      readFile: (path) ->
        fetch(path)
        .then (response) ->
          if 200 <= response.status < 300
            response.blob()
          else
            throw new Error(response.statusText)

  systemProxy = new Proxy systemTarget,
    get: (target, property, receiver) ->
      target[property] or
      ->
        postmaster.invokeRemote "system", property, arguments...

  # TODO: Also interesting would be to proxy observable arguments where we
  # create the receiver on the opposite end of the membrane and pass messages
  # back and forth like magic

  initializeOnZineOS = ({id}) ->
    applicationTarget.id = id

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
  Postmaster: Postmaster
  UI: UI
  version: version

SystemClient.applyExtensions = ->
  require "./lib/extensions"

Object.assign SystemClient,
  Observable: UI.Observable
  UI: UI

module.exports = SystemClient
