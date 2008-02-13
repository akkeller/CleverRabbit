#!/usr/bin/perl

#
#   get_definitions.command
#   (RomanToKhmer.app)
#
#   Copyright (c) 2002-2005 A. Karl Keller (http://karlk.net)
#
#   This code is open-source, free software, made available without warranty under
#   the terms of the GNU General Public License, either version 2 or later (see 
#   http://www.gnu.org/licenses/gpl.html or included copy); as such, it may be 
#   redistributed and/or modified in accordance with that document.
#
                                                                            

# $local_testing = 1;

$KEY_FILE = "current.txt";
$DOWNLOAD_DIR = "downloaded_definitions";
$ACTIVE_DIR = "active_definitions";
$EXTENSION = "tgz";

$MKDIR = "/bin/mkdir";
$CURL = "/usr/bin/curl";
$UNTARGZIP = "/usr/bin/tar -xzf";
$MV = "/bin/mv";
$LS = "/bin/ls";

if(!$local_testing)
{
    $DOWNLOAD_ADDR = "http://www.karlk.net/downloads/software/definitions/";
}else{
    $DOWNLOAD_ADDR = "http://ibook-akk.local/~karl/karlk.net/public_html/downloads/software/definitions/";
    `echo "Local RK testing build." > testing.txt`;
    `open -a TextEdit testing.txt`;
}

`$MKDIR $DOWNLOAD_DIR` unless -e $DOWNLOAD_DIR;
`$MKDIR $ACTIVE_DIR` unless -e $ACTIVE_DIR;

$current = `$CURL $DOWNLOAD_ADDR/$KEY_FILE`;
chomp $current;

`$CURL $DOWNLOAD_ADDR/$current.$EXTENSION > $DOWNLOAD_DIR/$current.$EXTENSION`;
`$UNTARGZIP $DOWNLOAD_DIR/$current.$EXTENSION -C $ACTIVE_DIR/`;




