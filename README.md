System Client
=============

Client lib to run apps on ZineOS and proxy messages to the OS through Postmaster.

Apps that want to integrate with ZineOS can use System Client to connect to
ZineOS through the system interface.

System Client includes the UI library so apps can use that as well.

Usage
-----

Setup:

```coffee
SystemClient = require "system-client"

{application, system, UI} = SystemClient()

system.ready()
.then -> # Connected to ZineOS
.catch -> # Not connected to ZineOS
```

Making ZineOS system calls:

```coffee
system.writeFile(path, blob)
```

The system calls are sent to the parent frame through postmessage. All arguments
need to be able to survive the structured clone algorithm. A promise is returned
that will be fulfilled with the result of the remote ivnocation or rejected with
an error.
