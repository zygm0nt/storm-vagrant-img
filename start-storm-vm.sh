#!/bin/sh

unlink bootstrap.sh
ln -s empty.sh bootstrap.sh

vagrant up
