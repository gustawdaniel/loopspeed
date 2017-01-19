#!/usr/bin/env bash

sudo mysql -u root inc -e "CALL inc_loop($1)";