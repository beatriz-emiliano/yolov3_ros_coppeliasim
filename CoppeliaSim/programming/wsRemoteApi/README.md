# WebSocket Remote API for CoppeliaSim

The WebSocket Remote API requires the [WS plugin](https://github.com/CoppeliaRobotics/simExtWS).

### Table of contents

 - [Compiling](#compiling)
 - [Protocol](#protocol)
     - [Request](#request)
     - [Response](#response)


### Compiling

1. Install required packages for [libPlugin](https://github.com/CoppeliaRobotics/libPlugin): see libPlugin's [README](external/libPlugin/README.md)
2. Checkout and compile
```text
$ git clone --recursive https://github.com/CoppeliaRobotics/wsRemoteApi
$ mkdir wsRemoteApi/build
$ cd wsRemoteApi/build
$ cmake ..
$ cmake --build .
$ cmake --install .
```

### Protocol

Connect WebSocket to the endpoint (by default on port 23050), send a message (see [request](#request) below), and read the response (see [response](#response) below). The request and response can be serialized to [JSON](https://www.json.org) or [CBOR](https://cbor.io). The response will be serialized using the same serialization format used in the request.

See also the example client `example.html`.

#### Request

A request is an object with fields:
- `func` (string) the function name to call;
- `args` (array) the arguments to the function;
- (optional) `id` (string) an identifier to correlate request with response.

Example:

```json
{
    "func": "sim.getObject",
    "args": ["/Floor"]
}
```

#### Response

A response is an object with fields:
- (optional) `id` (string) set to the same value of the request's `id` field;
- `success` (boolean) `true` if the call succeeded, in which case the `ret` field will be set, or `false` if the call failed, in which case the `error` field will be set;
- `ret` (array) the return values of the function;
- `error` (string) the error message.

Example:

```json
{
    "success": true,
    "ret": [37]
}
```

In case of error, the exception message will be present:

```json
{
    "success": false,
    "error": "Object does not exist. (in function 'sim.getObject')"
}
```
