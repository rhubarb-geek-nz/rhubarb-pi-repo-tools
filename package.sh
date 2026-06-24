#!/bin/sh -e
#
#  Copyright 2021, Roger Brown
#
#  This file is part of rhubarb pi.
#
#  This program is free software: you can redistribute it and/or modify it
#  under the terms of the GNU General Public License as published by the
#  Free Software Foundation, either version 3 of the License, or (at your
#  option) any later version.
# 
#  This program is distributed in the hope that it will be useful, but WITHOUT
#  ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
#  FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
#  more details.
#
#  You should have received a copy of the GNU General Public License
#  along with this program.  If not, see <http://www.gnu.org/licenses/>
#
# $Id: package.sh 47 2021-05-16 16:27:51Z rhubarb-geek-nz $
#

SVNVERS=-2

for d in $0 repo-*
do
	svn log -q $d > /dev/null
	COUNT=$(svn log -q $d | grep -v "\------" | wc -l)

	SVNVERS=$(echo $SVNVERS+$COUNT | bc)
done

VERSION=1.0.$SVNVERS
PKGNAME=rhubarb-pi-repo-tools
OUTDIR_DIST=$(pwd)
OPSYS=$(uname)
OPSYSLOWER=$(uname | tr "[:upper:]" "[:lower:]")
OPSYSREL=$(uname -r | sed "y/./ /" | while read A B; do echo $A; break; done)
DEPLIST=json-yaml

clean()
{
	rm -rf MANIFEST PLIST root 
}

trap clean 0

clean

mkdir -p root/usr/local/bin

cp repo-* root/usr/local/bin

(
	cat <<EOF
name $PKGNAME
version $VERSION
desc Repository tools to list and verify for $OPSYS:$OPSYSREL
www https://sourceforge.net/projects/rhubarb-pi/
origin misc/repo/tools
comment Repository tools for $OPSYS:$OPSYSREL
maintainer rhubarb-geek-nz@users.sourceforge.net
arch $OPSYSLOWER:$OPSYSREL:*
abi $OPSYS:$OPSYSREL:*
prefix /usr/local/bin
licenses: [
    "GPL3"
]
categories: [
    "misc"
]
EOF
	echo "deps: {"
	for d in $DEPLIST
	do
		ORIGIN=$(pkg info -q --origin $d)
		VERS=$(pkg info $d | grep Version | while read A B C D; do echo $C; break; done | sed "y/,/ /" | while read E F; do echo $E; done)
		if test "$d" = "json-yaml"
		then
			echo "   $d: {origin: $ORIGIN, version: $VERS}"
		else
			echo "   $d: {origin: $ORIGIN, version: $VERS},"
		fi
	done
	echo "}"
) > MANIFEST

(
	cd root/usr/local/bin
	ls repo-*
) > PLIST

if pkg create -M MANIFEST -o "$OUTDIR_DIST" -r root -v -p PLIST
then
	pkg info -F "$OUTDIR_DIST/$PKGNAME-$VERSION.txz"
	pkg info -l -d -F "$OUTDIR_DIST/$PKGNAME-$VERSION.txz"
fi
