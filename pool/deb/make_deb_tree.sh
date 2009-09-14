#!/bin/sh
apt-ftparchive packages . | gzip -9c > Packages.gz
apt-ftparchive packages . > Packages
apt-ftparchive sources --source-override . | gzip -9c > Source.gz
apt-ftparchive contents . | gzip -9c > Contents.gz
apt-ftparchive release  . > Release
