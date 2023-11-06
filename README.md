## Building

```
$ nix-build
```

## Running

Server:

```
$ ./result/bin/chat
```

Client:

```
$ ./result/bin/chat -host localhost
```

## Demo

| Server                           | Client                                        |
|----------------------------------|-----------------------------------------------|
| `$ ./result/bin/chat`            |                                               |
| `Waiting for client to connect.` |                                               |
|                                  | `$ ./result/bin/chat -host localhost`         |
| `Client connected.`              | `Connected to localhost.`                     |
|                                  |                                               |
|                                  | `Howdy, server!`                              |
| `<remote> Howdy, server!`        |                                               |
|                                  | `ack: 0.16ms`                                 |
|                                  |                                               |
| `Hey, client!`                   |                                               |
|                                  | `<remote> Hey, client!`                       |
| `ack: 0.14ms`                    |                                               |
|                                  |                                               |
|                                  | `How's it going`                              |
| `<remote> How's it going?`       |                                               |
|                                  | `ack: 0.11ms`                                 |
|                                  |                                               |
| `Functionally.`                  |                                               |
|                                  | `<remote> Functionally.`                      |
| `ack: 0.18ms`                    |                                               |
|                                  |                                               |
|                                  | `Welp, later!`                                |
| `<remote> Welp, later!`          |                                               |
|                                  | `ack: 0.13ms`                                 |
|                                  |                                               |
|                                  | `^C`                                          |
| `Remote disconnected.`           |                                               |
|                                  |                                               |
|                                  | `$ ./_build/default/chat.exe -host localhost` |
|                                  | `Started in client mode.`                     |
| `Client connected.`              | `Connected to localhost.`                     |
|                                  |                                               |
|                                  | `Me again.`                                   |
| `<remote> Me again.`             |                                               |
|                                  | `ack: 0.14ms`                                 |
