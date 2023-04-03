import sys
import cbor
import zmq

context = zmq.Context()
socket = context.socket(zmq.REP)
socket.bind(sys.argv[1])
module = {}
while True:
    req = cbor.loads(socket.recv())
    rep = {'success': True}
    
    req['cmd']=req['cmd']#.decode("utf-8")

    if req['cmd'] == 'loadCode':
        try:
            req['code']=req['code']#.decode("utf-8")
            exec(req['code'],module)
        except Exception as e:
            import traceback
            rep = {'success': False, 'error': traceback.format_exc()}
    elif req['cmd'] == 'callFunc':
        try:
            req['func']=req['func']#.decode("utf-8")
            func = module[req['func']]
            rep['ret'] = func(*req['args'])
        except Exception as e:
            import traceback
            rep = {'success': False, 'error': traceback.format_exc()}
    else:
        rep = {'success': False, 'error': f'unknown command: "{req["cmd"]}"'}

    socket.send(cbor.dumps(rep))