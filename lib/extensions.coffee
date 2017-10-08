# Add some utility readers to the Blob API
Blob::readAsText = ->
  file = this

  new Promise (resolve, reject) ->
    reader = new FileReader
    reader.onload = ->
      resolve reader.result
    reader.onerror = reject
    reader.readAsText(file)

Blob::getURL = ->
  Promise.resolve URL.createObjectURL(this)

Blob::readAsJSON = ->
  @readAsText()
  .then JSON.parse

Blob::readAsDataURL = ->
  file = this

  new Promise (resolve, reject) ->
    reader = new FileReader
    reader.onload = ->
      resolve reader.result
    reader.onerror = reject
    reader.readAsDataURL(file)

# Load an image from a blob returning a promise that is fulfilled with the
# loaded image or rejected with an error
Image.fromBlob = (blob) ->
  blob.getURL()
  .then (url) ->
    new Promise (resolve, reject) ->
      img = new Image
      img.onload = ->
        resolve img
      img.onerror = reject

      img.src = url
