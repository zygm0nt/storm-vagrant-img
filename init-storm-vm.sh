#!/bin/sh

unlink bootstrap.sh
ln -s init.sh bootstrap.sh

vagrant up
