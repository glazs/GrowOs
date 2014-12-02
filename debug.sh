#!/bin/bash

coffee -o out -m -c *.coffee
node-debug --no-debug-brk out/app.js