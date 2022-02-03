#!/bin/sh

# This prints any file under a __tests__ dir, that is not
# being ran by mocha, for not having a `.test.js` ext.
# e.g. sometimes I rename a file and forget the ext.

find $REPO/src  | grep __tests__ | grep .js$ | grep -v .test.js$
