#!/bin/sh

# First build the InterfaceBuilder library...
ln -s GormLib InterfaceBuilder
cd InterfaceBuilder
make install

# Now build Gorm itself...
cd ../
make

# Now install the palettes into the app and install
make install


