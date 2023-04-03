"use strict";

const WebSocketAsPromised = require('websocket-as-promised');

class RemoteAPIClient {
    constructor(host = 'localhost', port = 23050, codec = "cbor", opts = {}) {
        this.host = host;
        this.port = port;
        this.codec = codec;
        var packMessage;
        var unpackMessage;
        if(this.codec == 'cbor') {
            //this.websocket.binaryType = "arraybuffer";
            packMessage = data => CBOR.encode(data);
            unpackMessage = async data => CBOR.decode(await data.arrayBuffer());
        } else if(this.codec == "json") {
            packMessage = data => JSON.stringify(data);
            unpackMessage = data => JSON.parse(data);
        }
        var wsOpts = {
            packMessage,
            unpackMessage,
            // attach requestId to message as `id` field
            attachRequestId: (data, requestId) => Object.assign({id: requestId}, data),
            // read requestId from message `id` field
            extractRequestId: data => data && data.id,
        };
        for(var k in opts)
            wsOpts[k] = opts[k];
        this.websocket = new WebSocketAsPromised(`ws://${this.host}:${this.port}`, wsOpts);
    }

    async call(func, args) {
        var reply = await this.websocket.sendRequest({func, args});
        if(reply.success) {
            return reply.ret;
        } else {
            throw reply.error;
        }
    }

    async getObject(name) {
        var r = await this.call('wsRemoteApi.info', [name]);
        return this.getObject_(name, r[0]);
    }

    getObject_(name, _info) {
        const client = this;
        var ret = {}
        for(let k in _info) {
            var v = _info[k];
            if(Object.keys(v).length == 1 && v['func'] !== undefined)
                ret[k] = async function(...args) {
                    return await client.call(name + "." + k, args);
                };
            else if(Object.keys(v).length == 1 && v['const'] !== undefined)
                ret[k] = v['const'];
            else
                ret[k] = this.getObject(name + "." + k, null, null, v);
        }
        return ret
    }
}
