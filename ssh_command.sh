#!/bin/bash

sshpass -p 'raspberry' ssh -o StrictHostKeyChecking=no pi@$1 $2
wait
