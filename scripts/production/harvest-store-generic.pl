#!/usr/bin/perl

# This is not the best way to do this, unfortunately there is something fishy 
# about the pm8 and how it responds to SNMP get requests.  Using the Net::SNMP
# module exacerbates the problem, using snmpget from the command line does not, 
# go figure.
#
# 15-March-2011	charliep	Original coding. 
# 29-March-2011	charliep	Removed password.
# 08-March-2012	charliep	Re-wrote after stewie disk failure...
# 30-September-2012 alex seewald Re-wrote harvest script to be generic
use strict;
use warnings;
use DBD::Pg;

#these command line arguments come from the crontab

my $building_name = $ARGV[0];
my $ip = $ARGV[1];
my $amperage_correction = $ARGV[2];

my $timestamp;
my $pReal; 
my $database = "energy";
my $dbh; 
my $sth; 

$timestamp = time; 
$pReal = `java -cp /home/energy/scripts/production ModbusReadDemand $ip $amperage_correction`;
chomp($pReal); 
$pReal =~ s/"//g; 

$dbh = DBI->connect("dbi:Pg:dbname=$database") or die "Cannot connect to database $database";
$dbh->do("insert into electrical_energy values ('$building_name', $pReal, to_timestamp($timestamp))"); 
$dbh->disconnect;
exit(0); 
