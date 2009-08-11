#!/usr/local/bin/perl

###############################
# Filename: clarinUrlChecker.pl
# Filepath: U:\Scripts\URL-check\clarinUrlChecker.pl (Account: everic)
# SVN Location: svn.clarin.eu\metadata\trunk\URL-checker
# 
# Author: Evelyn Richter
# Last modified: 06 August 2009
#
# General Description:
# This script checks all URLs for Clarin resources and tools given in the Clarin mySQL database. 
# If a URL cannot be touched, a report is saved in the database column 'field_resource_urlcheck_value' 
# or 'field_tool_urlcheck_value' respectively. This report is in json format. 
#
# Comments: 
# - needs to either run on the CLARIN server or an SSH Tunnel 
#   to that server has to be established from where it is running
#	(ssh -L 33060:localhost:3306 USERNAME@clarin.mpi.nl )
# - ran again on 01 June 2009, added column names to the json output stored for URL errors
# - ran again and added some documentation on 6 Aug 2009
# - will have to be made a cron job when there is an automatic way of contacting the data providers
###############################

use strict;
use DBI;
use DBD::mysql;
use LWP::UserAgent;

# database handle to the clarin drupal database
my $dsn = 'dbi:mysql:drupal:127.0.0.1:33060'; 
my $dbh = DBI->connect($dsn, "evelyn", "3v3l1n") or die $DBI::errstr;

# required resource sql
my $res_sql = "SELECT vid, field_metadata_link_url, field_reference_link_url, ";
$res_sql .= "field_interface_specification_url, field_input_schema_reference_url, ";
$res_sql .= "field_output_schema_url, field_location_webservice_url, ";
$res_sql .= "field_input_schema_reference_0_url, field_output_schema_0_url FROM content_type_resource";

# required tool sql
my $tool_sql = "SELECT vid, field_tool_document_link_value, field_tool_reference_link_value, ";
$tool_sql .= "field_tool_webservice_link_value FROM content_type_tool";

# select all links from resource table
my $res_urls = $dbh->selectall_arrayref($res_sql);
# select all links from tools table
my $tool_urls = $dbh->selectall_arrayref($tool_sql);

# check the URLs and return resulting array ref
# print "Start checking URLs for resources\n";
$res_urls = checkURL("resource", $res_urls);
# print "Start checking URLs for tools\n";
$tool_urls = checkURL("tool", $tool_urls);

# clear the urlcheck database columns
# print "Truncating urlcheck columns\n";
truncateCol($dbh, "resource", "tool");

# save to the database
# print "Start saving resources to DB\n";
saveToDatabase("resource", $res_urls, $dbh);
# print "Start saving tools to DB\n";
saveToDatabase("tool", $tool_urls, $dbh);


###############################
# Finds URL, calls touchURL(), updates status of URL check in array reference
#
# Arguments: type (resource/tool), array reference of file matrix
# Returns: updated array reference
###############################

sub checkURL{
	my $type = shift @_;
	my $aref = shift @_;
	my $count = scalar @{$aref->[0]};

	for (my $k = 0; $k < scalar @$aref; $k++){
		my @brokenURLs; 
		for (my $i = 1; $i < $count; $i++){
			# check only required if URL specified
			if ($aref->[$k][$i] ne ""){
				my $result;
				# URL has to start with http://, https://, ftp:// or sftp://, if not, then http:// added
				if (!($aref->[$k][$i] =~ m/^http:\/\//g) && !($aref->[$k][$i] =~ m/^https:\/\//g) && !($aref->[$k][$i] =~ m/^ftp:\/\//g) && !($aref->[$k][$i] =~ m/^sftp:\/\//g)){
					# check whether the URL can be touched
					$result = touchURL("http://" . $aref->[$k][$i]);
				}
				else {
					# check whether the URL can be touched
					$result = touchURL($aref->[$k][$i]);
				}
				
				if ($result){
					# $result is true when error code sent along
					push @brokenURLs,  "\"Code\" : \"" . $result . "\",\n\t\t\t\"URL\" : \"" . $aref->[$k][$i] . "\",\n\t\t\t\"Column\" : \"" . getCol($type, $i) . "\"";
				}
			} 
		}
		# if there are any broken URLs, convert them to a string and save them in array ref
		if (scalar @brokenURLs != 0){
			$aref->[$k][$count] = json(@brokenURLs);
		}
		else {
			$aref->[$k][$count] = "";
		}
	}
	return $aref; 
}

###############################
# Get the column name from the database table
#
# Arguments: type (resource/tool), index of column in array ref
# Returns: column name
###############################

sub getCol{
	my $type = shift @_;
	my $i = shift @_;
	
	if ($type eq "tool"){
		if ($i == 1){
			return "field_tool_document_link_value";
		}
		elsif($i == 2){
			return "field_tool_reference_link_value";
		}
		else {
			return "field_tool_webservice_link_value";
		}
	}
	elsif ($type eq "resource"){
		if ($i == 1){
			return "field_metadata_link_url";
		}
		elsif($i == 2){
			return "field_reference_link_url";
		}
		elsif($i == 3){
			return "field_interface_specification_url";
		}
		elsif($i == 4){
			return "field_input_schema_reference_url";
		}
		elsif($i == 5){
			return "field_output_schema_url";
		}
		elsif($i == 6){
			return "field_location_webservice_url";
		}
		elsif($i == 7){
			return "field_input_schema_reference_0_url";
		}
		else {
			return "field_output_schema_0_url";
		}
	}
	else {
		die "Unknown type. Known types are resources and tools.";
	}
}

###############################
# Produces JSON string of the form: 
#
# {
#   "Errors" : [
#     {
#       "Number" : "0",
#       "Code" : "404",
#       "URL" : "http://mpi.nl"
#     },
#     {
#       "Number" : "1",
#       "Code" : "404",
#       "URL" : "http://mpi.nl"
#     }
#   ]
# } 
#
# Comment: Not elegant, but produces desired output. 
# More elegant version would be creating a perl data 
# structure which converts to the desired JSON output 
# by means of the JSON module. 
#
# Arguments: array with URL check errors
# Returns: json string
###############################

sub json{
	my @array = @_;
	my $string = "{\n\t\"Errors\" : [\n";
	my $i;

	for ($i = 0; $i < scalar @array; $i++){
		$array[$i] = "\t\t{\n\t\t\t\"Number\" : \"" . $i . "\",\n\t\t\t" . $array[$i] . "\n\t\t\}";
	}
	
	$string .= join (",\n", @array);
	$string .= "\n\t]\n}";
	return $string;
}

###############################
# Prints the array reference, can be used at different stages 
# in the script for debugging
#
# Arguments: array ref of file matrix
# Returns: nothing
###############################

sub printArrayRef{
	my $aref = shift @_;
	for (my $i = 0; $i < scalar @$aref; $i++){
		my $k = 0;
		foreach my $x (@{$aref->[$i]}){
			print $k . ": " . $x . "\t";
			$k++;
		}
		print "\n";
	}
}

###############################
# Prints the array reference to a file, can be used for debugging
#
# Arguments: array ref of file matrix, file path for output file
# Returns: nothing
###############################

sub printFile{
	my $aref = shift @_;
	my $path = shift @_;
	$path = ">" . $path;
	my $str = "";
	for (my $i = 0; $i < scalar @$aref; $i++){
		foreach my $x (@{$aref->[$i]}){
			$str .= '"' . $x . '",';
		}
		$str .= "\n";
	}
	open(OUT, $path); 
	print OUT $str;
	close(OUT);
}

###############################
# Prints the error reports to the database via update()
#
# Arguments: type (tool/resource), primary key, error message
# Returns: nothing
###############################

sub saveToDatabase{
	my $type = shift @_;
	my $aref = shift @_;
	my $dbh = shift @_;
	
	foreach my $x (@{$aref}){
		if ($x->[scalar @$x - 1]){
			update($type, $x->[0], $x->[scalar @$x - 1], $dbh) or die "Could not run update for vid: " . $x->[0];
		}
	}
	#print "Done Saving to DB\n";
}

###############################
# Checks whether a URL can be touched 
# (partly taken from lari.pl from Alexander Koenig)
#
# Arguments: individual url
# Returns: true (an error response code) or false (when URL works)
###############################

sub touchURL{
	my $url = shift @_;
	my $ok = 1;
	
	# whitelist with URLs that are known to respond with an error, but work
	# will have to be updated whenever a user has a working URL which throws 
	# an error in this script anyway
	my @whitelist;
	$whitelist[0] = "http://datubaze.ema.lv/szf/?bbaa=cGFy";
	$whitelist[1] = "http://datubaze.ema.lv";
	
	# check whether the URL is on the whitelist
	foreach my $wl (@whitelist){
		if ($url eq $wl){
			$ok = 0;
		}
	}
	
	unless ($ok == 0){
		# create an LWP User Agent for checking remote URLs
		my $ua = LWP::UserAgent->new(max_redirect => 15); 
		$ua->timeout(60); 
		my $http_result = $ua->head($url);
		if (($http_result->is_success)){
			return 0;
		}
		else {
			my $response = $ua->get($url);
			if ($response->is_success) {
				return 0;
			}
			else {
				return $response->code;
			}
		}
	}
	else {
		return $ok;
	}
}


###############################
# Truncates all entries in the URL checking column of the database
#
# Arguments: database handle, several types (resource/tool)
# Returns: nothing
###############################

sub truncateCol{
	my $dbh = shift @_;
	my $type1 = shift @_;
	my $type2 = shift @_;
	
	foreach my $t ($type1, $type2){
		my $sql = "UPDATE content_type_" . $t . " SET field_". $t . "_urlcheck_value = NULL WHERE field_". $t . "_urlcheck_value IS NOT NULL";
		my $prep = $dbh->prepare($sql) or die $dbh->errstr;
		$prep->execute();
	}
}


###############################
# Prints the URL error report to the database
#
# Arguments: type (tool/resource), primary key, error message
# Returns: nothing
###############################

sub update{
	my $type = shift @_;
	my $vid = shift @_;
	my $msg = shift @_;
	my $dbh = shift @_;
	
	# put SQL string together
	my $sql = "UPDATE content_type_" . $type . " SET field_". $type . "_urlcheck_value = '" . $msg . "' WHERE vid = " . $vid;

	my $prep = $dbh->prepare($sql) or die $dbh->errstr;
	$prep->execute();
}


