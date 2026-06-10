#!/usr/bin/env bash
curl -s -H "HOST: nginx-dev.example.com" http://192.168.104.201 # your gateway ip
curl -s -H "HOST: nginx-stage-blue.example.com" http://192.168.104.201 # your gateway ip
curl -s -H "HOST: nginx-stage-green.example.com" http://192.168.104.201 # your gateway ip
