#!/bin/bash

BASE='/some/path'

adb push .libs ${BASE}
for DIR in misc mpf mpn mpq mpz rand; do adb push ${DIR}/.libs ${BASE}/$DIR; done
