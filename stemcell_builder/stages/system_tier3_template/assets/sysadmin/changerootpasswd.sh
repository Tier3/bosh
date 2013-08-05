#!/bin/sh

usermod -p `mkpasswd $1` root
