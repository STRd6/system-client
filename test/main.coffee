mocha.globals(['OBSERVABLE_ROOT_HACK'])

SystemClient = require "../main"

describe "System Client", ->
  it "should extend native Blob APIs when applying extensions", ->
    assert !Blob::readAsText

    SystemClient.applyExtensions()
    assert Blob::readAsText

  it "should return system and application proxies", ->
    {system, application} = SystemClient()

    assert system
    assert application

  it "should connect when ready is called", (done) ->
    {system, application} = SystemClient()

    system.ready()
    .catch (e) ->
      console.warn e
      done()

    return
