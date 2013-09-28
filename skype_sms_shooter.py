#!/usr/bin/python


import Skype4Py
import time

import getopt
import sys 

RECIPIENT = None
BODY = None

def usage() :
    
    print """skype-sms-shooter --recipient='<recipient>' --body='<body>'
   It's important to wrap body in particular in single quotes in order
   to bypass shell expansion."""

opts, args = getopt.getopt(sys.argv[1:], "", ["body=", "recipient="]) ;
for (opt, arg) in opts :
    if opt == "--body" :
        BODY = arg
    elif opt == "--recipient" :
        RECIPIENT = arg

if not (BODY and RECIPIENT) :
    usage() ;
    sys.exit(1)

print "sending text '%s' to number '%s'" % (BODY, RECIPIENT)

if len(BODY) > 160 :
    sys.stderr.write("RECIPIENT CONTENT MUST BE SHORTER THAN 160 CHARACTERS") 
    sys.exit(1)



# instatinate event handlers and Skype class
skype = Skype4Py.Skype()

# start Skype client if it isn't running
if not skype.Client.IsRunning:
    skype.Client.Start()

# send SMS message
sms = skype.SendSms(RECIPIENT, Body=BODY)

# event handlers will be called while we're sleeping
time.sleep(2)
