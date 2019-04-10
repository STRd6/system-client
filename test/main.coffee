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

    assert system.client.Bindable
    assert system.client. Observable
    assert system.client.UI

  it "should provide FileIO as a util", ->
    {system} = SystemClient()

    assert system.client.util.FileIO

    handlers = system.client.util.FileIO()

    assert.equal handlers.currentPath(), ""

  it "should provide UI and Observable", ->
    {UI, Observable} = SystemClient

    assert UI
    assert.equal typeof Observable, "function"

  it "should queue up messages until a delegate is assigned", ->
    new Promise (resolve, reject) ->
      {system, application} = SystemClient()

      {postmaster} = system.client

      postmaster.delegate.application "test1", "yo"
      .then (c) ->
        assert.equal c, "wat"

      postmaster.delegate.application "test2", "yo2"
      .then (d) ->
        assert.equal d, "heyy"
        resolve()

      application.delegate =
        test1: (a) ->
          assert.equal a, "yo"

          return "wat"

        test2: (b) ->
          assert.equal b, "yo2"
          return "heyy"

  it "should connect when ready is called", (done) ->
    {system, application} = SystemClient()

    system.ready()
    .catch (e) ->
      console.warn e
      done()

    return
