mocha.globals(['OBSERVABLE_ROOT_HACK'])

SystemClient = require "../main"

describe "System Client", ->
  it "should extend native Blob APIs when applying extensions", ->
    assert !Blob::readAsText

    SystemClient.applyExtensions()
    assert Blob::readAsText
