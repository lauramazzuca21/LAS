#!/bin/bash

IP_HOST=$1

ssh $IP_HOST ps auxw | wc -l
