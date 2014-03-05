#!/usr/bin/perl

# harvest-store-oa.pl
#
# This is not the best way to do this, unfortunately there is something fishy 
# about the pm8 and how it responds to SNMP get requests.  Using the Net::SNMP
# module exacerbates the problem, using snmpget from the command line does not, 
# go figure.
#
# 15-March-2011	charliep	Original coding. 
# 29-March-2011	charliep	Removed password.
# 08-March-2012	charliep	Re-wrote after stewie disk failure...

use strict;
use warnings;
use DBD::Pg;

my $timestamp;
my $pReal; 
my $database = "energy";
my $dbh; 
my $sth; 

$timestamp = time; 
$pReal = `java --cp /home/energy/scripts/production ModbusReadDemand 159.28.165.105 31.25`;
chomp($pReal); 
$pReal =~ s/"//g; 
# printf("At %d pReal = %d\n",  $timestamp, $pReal); 

$dbh = DBI->connect("dbi:Pg:dbname=$database");
if (!$dbh) {
	die "Cannot connect to database $database";
}

$dbh->do("insert into electrical_energy values ('OA', $pReal, to_timestamp($timestamp))"); 

$dbh->disconnect;
exit(0); 
