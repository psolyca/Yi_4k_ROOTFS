#! /usr/bin/env python
#by apple wang
import json
import os
import re
import sys
import socket
import time
import urllib2
camaddr = "127.0.0.1"
camport = 7878
'''
tim = urllib2.urlopen("http://api.xiaoyi.com/v2/ipc/sync_time?hmac=BIke7GBrJXU6Qe41glDqGUkYNp8%3D" )
data= tim.read()
tim.close()
b=json.loads(data)
hh=b["time"]/1000
os.system("date -s @%s" %hh)
'''
srv = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
srv.connect((camaddr, camport))
srv.send('{"msg_id":257,"token":0, "heartbeat":0, "param":0}')
data = srv.recv(512)
if "rval" in data:
	token = re.findall('"param":*([0-9]+)*',data)[0]
	print token
else:
	data = srv.recv(512)
	if "rval" in data:
		token = re.findall('"param": (.+) }',data)[0]

tosend = '{"msg_id" : 3,"token" : %s}' %token
print tosend
srv.send(tosend)
data = srv.recv(512)
print data
ISOTIMEFORMAT='%Y-%m-%d %X'
tosend = '{"msg_id":2,"token":%s, "type":"camera_clock", "param":"%s"}' %(token,time.strftime(ISOTIMEFORMAT,time.gmtime(time.time())))
print tosend
srv.send(tosend)
data = srv.recv(512)
print data
tosend = '{"msg_id":259,"token":%s,"param":"none_force"}' %token
print tosend
srv.send(tosend)
data = srv.recv(512)
print data

tosend = '{"msg_id":7,"type":"vf_start"}'
srv.send(tosend)
data = srv.recv(512)
print data

print "vf_start to rtos system ."

'''
print "Press CTRL+C to end this streamer"
while 1:
	time.sleep(1)
'''
