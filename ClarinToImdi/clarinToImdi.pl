#!n:\perl\bin

###############################
# Filename: clarinToImdi.pl
# SVN location: 
#
# Author: Evelyn Richter
# Last modified: 13 Aug 2009
#
# General information: 
# This script converts Clarin resource metadata saved in a mySQL database into Catalogue imdi files. 
# Additionally, parent corpus files are produced that link to the respective catalogue file. 
# Finally, a top node with links to all corpus files is produced. 
#
# Requirements:
# - has to be run on Clarin server or via an SSH tunnel (ssh -L 33060:localhost:3306 USERNAME@clarin.mpi.nl)
# - Clarin database login (username, password) with select permissions
# - the module XML::Smart::Data has to be modified a bit to avoid base64 encoding of UTF-8 characters in attributes (see sub _data in Data.pm)
# - the following command line arguments:
#	1. Clarin db username 
#	2. Clarin db password
# 	3. the current ISO 639.3 code list from the ISO authority 
#	4. the country/continent mapping from LINGUIST List
#	5. an XML input file with XML header 
#	6. an output directory
###############################

use strict;
use DBD::mysql;
use DBI;
use Encode;
use XML::Smart;

# error message when command line arguments missing
my $error = "Please enter the following command line arguments: Clarin db username & password, the current ISO 639.3 code list from the ISO authority, the country/continent mapping from LINGUIST List, an XML input file with XML header and an output directory.\n";

# reading in command line arguments
my $dbUsername = $ARGV[0] or die $error;
my $dbPassword = $ARGV[1] or die $error;
my $langCodesFile = $ARGV[2] or die $error;
my $LLcountryInfoFile = $ARGV[3] or die $error;
my $XmlImportFile = $ARGV[4] or die $error;
my $outputDir = $ARGV[5] or die $error;

unless ($outputDir =~ m/\/$/){
	$outputDir .= "/";
}

# database handle to the clarin drupal database
my $dsn = 'dbi:mysql:drupal:127.0.0.1:33060'; 
my $dbh = DBI->connect($dsn, $dbUsername, $dbPassword) or die $DBI::errstr;
$dbh->do("set character set utf8"); # essential to ensure proper UTF-8 extraction

# required resource sql
my $res_sql = "SELECT ctr.nid, ctr.vid, n.title, ctr.field_languages_other_value, ctr.field_description_value, ctr.field_institute_value, ctr.field_creator_value, ctr.field_year_value, "; 
$res_sql .= "ctr.field_end_creation_date_value, ctr.field_format_value, ctr.field_metadata_link_url, ctr.field_publications_value, ctr.field_reference_link_url, ";
$res_sql .= "ctr.field_resource_available_value, ctr.field_ethical_reference_value, ctr.field_legal_reference_value, ctr.field_license_type_value, ctr.field_description_0_value, ";
$res_sql .= "ctr.field_contact_person_value, ctr.field_longterm_preservation_value, ctr.field_location_0_value, ctr.field_content_type_value, ctr.field_format_detailed_value, ";
$res_sql .= "ctr.field_quality_value, ctr.field_applications_value, ctr.field_project_value, ctr.field_size_value, ctr.field_distribution_form_value, ctr.field_access_value, ";
$res_sql .= "ctr.field_source_0_value, ctr.field_date_1_value, ctr.field_type_value, ctr.field_format_detailed_1_value, ctr.field_schema_reference_value, ctr.field_size_0_value, ";
$res_sql .= "ctr.field_access_2_value, ctr.field_resource_urlcheck_value ";
$res_sql .= "FROM node AS n, content_type_resource AS ctr WHERE ctr.nid = n.nid and ctr.vid = n.vid ORDER BY ctr.nid, ctr.vid";

# select information from resource table
my $resources = $dbh->selectall_arrayref($res_sql);

# get reference language codes
my $langcodes = getCodes($langCodesFile);

# get country information for mapping to continents/iso codes
my $LLcountryinfo = getCountryInfo($LLcountryInfoFile);

# begin top node XML
my $topnode = makeXmlHeader($XmlImportFile, "Corpus");
$topnode->{Name}->content("Clarin_LRT_Inventory");
$topnode->{Title}->content("Clarin LRT Inventory");
$topnode->{Description}->content("One of the goals of CLARIN is to setup a full-fledged registry to which one can add any collection of language resources and services (WP2). A second goal is to get a good overview about language resources and technology (WP5) and a third goal is to get a deep overview about the rights and license situation (WP7). Therefore, we have set up an online system for creating an inventory of LRT which can be used for generating these overviews, but which can be re-used to later bootstrap the real registry and which can be dynamically extended.");
$topnode->{Description}{LanguageId} = "ISO639-3:eng";

my $i = 0;
foreach my $res (@{$resources}){
	# if ($res->[0] = 1355){
	# get the resource types, countries, languages from the database for the respective resource
	my $res_types = $dbh->selectall_arrayref("SELECT field_resource_type_value FROM content_field_resource_type	AS cfrt WHERE cfrt.nid = " . $res->[0] .  " AND cfrt.vid = " . $res->[1] . " AND TRIM(field_resource_type_value) IS NOT NULL AND TRIM(field_resource_type_value) != 'Web Service' ORDER BY field_resource_type_value");
	my $res_langs = $dbh->selectall_arrayref("SELECT field_languages_value FROM content_field_languages	AS cfl WHERE cfl.nid = " . $res->[0] .  " AND cfl.vid = " . $res->[1] . " AND TRIM(field_languages_value) IS NOT NULL ORDER BY field_languages_value");
	my $res_inst = $dbh->selectall_arrayref("SELECT field_org_institution_value, field_org_workingunit_value, cto.nid, cto.vid FROM content_type_organisation AS cto, content_field_institute_fromlist AS cfif WHERE cto.nid = cfif.field_institute_fromlist_nid AND cfif.nid = " . $res->[0] . " AND cfif.vid = " . $res->[1]);
	my $res_countries = $dbh->selectall_arrayref("SELECT field_country_value FROM content_field_country AS cfc WHERE cfc.nid = " . $res->[0] .  " AND cfc.vid = " . $res->[1] . " AND TRIM(field_country_value) IS NOT NULL ORDER BY field_country_value");
	my $res_worklang = $dbh->selectall_arrayref("SELECT field_working_languages_value FROM content_field_working_languages AS cfwl WHERE cfwl.nid = " . $res->[0] .  " AND cfwl.vid = " . $res->[1] . " AND TRIM(field_working_languages_value) IS NOT NULL ORDER BY field_working_languages_value");
	my $res_worklang0 = $dbh->selectall_arrayref("SELECT field_working_languages_0_value FROM content_field_working_languages_0 AS cfwl WHERE cfwl.nid = " . $res->[0] .  " AND cfwl.vid = " . $res->[1] . " AND TRIM(field_working_languages_0_value) IS NOT NULL ORDER BY field_working_languages_0_value");
	my $coords = ();
	if ($res_inst && scalar @{$res_inst} > 0){
			$coords = $dbh->selectall_arrayref("SELECT latitude, longitude FROM location AS lo, location_instance AS li WHERE li.nid = " . $res_inst->[0][2] . " AND li.vid = " . $res_inst->[0][3] . " AND li.lid = lo.lid");
	}
	
	if (scalar @{$res_types} != 0){
		# create IMDI file
		my ($path, $name) = makeImdi($res, $res_types, $res_langs, $res_inst, $res_countries, $res_worklang, $res_worklang0, $coords, $langcodes, $LLcountryinfo, $XmlImportFile, $outputDir);
		$name =~ s/"/&quot;/g;
		$topnode->{CorpusLink}[$i]->content($path);
		$topnode->{CorpusLink}[$i]{Name} = $name;
		$i++;
	}
	#}
}

my $toppath = $outputDir . "clarinLRT-" . getTodayDate() . ".imdi";
printFile($toppath, $topnode->data());

###############################
# Finds ISO 639.3 code for a given language name, otherwise sets the code to "Unknown"
#
# Arguments: input filename, array ref with language code data
# Returns: matrix with data
###############################

sub findCode{
	my $langname = shift @_;
	my $langcodes = shift @_;
	my $code;

	foreach my $lc (@{$langcodes}){
		if ($langname eq $lc->[6]){
			if ($code){
				# there are two languages with this name, so the code cannot be determined
				print "ambig\n";
				return "Unknown";
			}
			$code = "ISO639-3:" . $lc->[0];
		}
	}
	
	if ($code){
		return $code;
	}
	else {
		return "Unknown";
	}
}

###############################
# Finds the continent for a country by comparing it to the information from the LINGUIST List database
#
# Arguments: country name, array ref of LL db info
# Returns: continent name or "Unknown"
###############################

sub findContinent{
	my $country = shift @_;
	my $info = shift @_;
	my $cont = "Unknown";
	my $reg1;
	my $reg2;
	
	for (my $i = 0; $i < scalar @{$info}; $i++){
		if ($country eq $info->[$i][1]){
			$reg1 = $info->[$i][2];
			$reg2 = $info->[$i][3];
			
			$cont = testIsoContinents($reg1);

			if ($cont eq "Unknown"){
				if ($reg1 eq "Australasia"){
					$cont = "Australia";
				}
				elsif ($reg1 eq "West Indies" || $reg1 eq "Central America"){
					$cont = "Middle America";
				}
				elsif ($reg1 eq "Pacific Islands"){
					$cont = "Oceania";
				}
				elsif ($reg1 eq "Middle East"){
					if ($reg2){
						return testIsoContinents($reg2);
					}
					else{
						return "Unknown";
					}
				}
			}
			
			if ($reg2){
				my $cont2 = testIsoContinents($reg2);
				
				if ($cont2 eq "Unknown"){
					if ($reg1 eq "Australasia"){
						$cont2 = "Australia";
					}
					elsif ($reg1 eq "West Indies" || $reg1 eq "Central America"){
						$cont2 = "Middle America";
					}
					elsif ($reg1 eq "Pacific Islands"){
						$cont2 = "Oceania";
					}
					elsif ($reg1 eq "Middle East"){
						return "Unknown";
					}
				}
				
				if ($cont2 ne "Unknown"){
					# will not validate, how to solve this?
					return $cont . ", " . $cont2;
				}
			}
		}
	}
}


###############################
# Reads in an input file with language codes
#
# Arguments: input filename
# Returns: matrix with data
###############################

sub getCodes{
	my $filename = shift @_;
	
	my $aref = ();
	my $i = 0;
	open(IN,$filename);
	my @lines = <IN>;
	close(IN);
		
	while (scalar @lines > 0){
		my $line = shift @lines;
		if ($line =~ m/^#/){
			next;
		}
		# line breaks and carriage returns deleted from line
		$line =~ s/\r?\n//g;
		my @temp = split /\t/, $line;
		my $k = 0;
		foreach my $cell (@temp){
			$aref->[$i][$k] = $cell;
			$k++;
		}
		$i++;
	}
	return $aref;

}

###############################
# Reads in an input file with country information extracted from LINGUIST List database
#
# Arguments: input filename
# Returns: matrix with data
###############################

sub getCountryInfo{
	my $filename = shift @_;
	
	my $aref = ();
	my $i = 0;
	open(IN, $filename);
	my @lines = <IN>;
	close(IN);
		
	while (scalar @lines > 0){
		my $line = shift @lines;
		# line breaks and carriage returns deleted from line
		$line =~ s/\r?\n//g;
		my @temp = split /,/, $line;
		my $k = 0;
		foreach my $cell (@temp){
			$aref->[$i][$k] = $cell;
			$k++;
		}
		$i++;
	}
	return $aref;
}

###############################
# Gets today's date and returns a formatted string (YYYY-MM-DD)
#
# Arguments: nothing
# Returns: date string
###############################

sub getTodayDate{
		my @f = (localtime)[3..5]; # grabs day/month/year values
		return ($f[2] + 1900) . "-" . (sprintf "%02d", ($f[1] + 1)) . "-" . (sprintf "%02d", $f[0]);
}

###############################
# Creates the XML structure and content for the imdi file from one resource entry
#
# Arguments: resource information, resource types, languages, institution, countries, working languages (2), 
# 			 langcodes (for comparison), countryinfo (incl iso codes, for comparison)
# Returns: nothing (xml data structure is given to printFile() in the end which prints the imdi file in a given directory)
# 
# Other requirements: testXMLimport.xml with xml declaration line incl encoding set to utf-8 and root element
###############################

sub makeImdi{
	my $info = shift;
	my $types = shift;
	my $langs = shift;
	my $inst = shift;
	my $countries = shift;
	my $wlangs = shift;
	my $wlangs0 = shift;
	my $geocoords = shift;
	my $langcodes = shift;
	my $countryinfo = shift;
	my $baseFile = shift;
	my $filepath = shift;
	
	# Create XML object and load imdi template file
	my $p = makeXmlHeader($baseFile, "Catalogue");
	
	# Name
	$p->{Name}->content($info->[2]);
	
	# Title
	$p->{Title}->content($info->[2]);
	
	# Id - always empty, set by Lamus?
	$p->{Id}->set_node();
	
	# Description
	$p->{Description}->content($info->[4]);
	$p->{Description}{LanguageId} = "Unspecified";
	
	# Document Languages
	if (scalar @{$wlangs} > 0){
		for (my $i = 0; $i < scalar @{$wlangs}; $i++){
			$p->{DocumentLanguages}{Language}[$i]{Id}->content(findCode($wlangs->[$i][0], $langcodes));
			$p->{DocumentLanguages}{Language}[$i]{Name}->content($wlangs->[$i][0]);
			$p->{DocumentLanguages}{Language}[$i]{Name}{Link} = "http://www.mpi.nl/IMDI/Schema/MPI-Languages.xml";
			$p->{DocumentLanguages}{Language}[$i]{Name}{Type} = "OpenVocabulary";
		}
	}
	elsif(scalar @{$wlangs0} > 0){
		for (my $i = 0; $i < scalar @{$wlangs0}; $i++){
			$p->{DocumentLanguages}{Language}[$i]{Id}->content(findCode($wlangs0->[$i][0], $langcodes));
			$p->{DocumentLanguages}{Language}[$i]{Name}->content($wlangs0->[$i][0]);
			$p->{DocumentLanguages}{Language}[$i]{Name}{Link} = "http://www.mpi.nl/IMDI/Schema/MPI-Languages.xml";
			$p->{DocumentLanguages}{Language}[$i]{Name}{Type} = "OpenVocabulary";
		}
	}
	else {
		$p->{DocumentLanguages}->set_node();
	}
	
	# Subject Languages
	if (scalar @{$langs} > 0){
		for (my $i = 0; $i < scalar @{$langs}; $i++){
			$p->{SubjectLanguages}{Language}[$i]{Id}->content(findCode($langs->[$i][0], $langcodes));
			$p->{SubjectLanguages}{Language}[$i]{Name}->content($langs->[$i][0]);
			$p->{SubjectLanguages}{Language}[$i]{Name}{Link} = "http://www.mpi.nl/IMDI/Schema/MPI-Languages.xml";
			$p->{SubjectLanguages}{Language}[$i]{Name}{Type} = "OpenVocabulary";
			$p->{SubjectLanguages}{Language}[$i]{Dominant}->content("Unknown");
			$p->{SubjectLanguages}{Language}[$i]{SourceLanguage}->content("Unknown");
			$p->{SubjectLanguages}{Language}[$i]{TargetLanguage}->content("Unknown");
		}
	}
	else {
		$p->{SubjectLanguages}->set_node();
	}
	
	# Location - multiple, might need to be changed depending on schema decision
	if (scalar @{$countries} > 0){
		for (my $i = 0; $i < scalar @{$countries}; $i++){
			$p->{Location}[$i]{Continent}->content(findContinent($countries->[$i][0], $countryinfo));
			$p->{Location}[$i]{Continent}{Link} = "http://www.mpi.nl/IMDI/Schema/Continents.xml";
			$p->{Location}[$i]{Continent}{Type} = "OpenVocabulary";
			$p->{Location}[$i]{Country}->content($countries->[$i][0]);
			$p->{Location}[$i]{Country}{Link} = "http://www.mpi.nl/IMDI/Schema/Countries.xml";
			$p->{Location}[$i]{Country}{Type} = "ClosedVocabulary";
		}
	}
	else {
		$p->{Location}->set_node();
		$p->{Location}{Continent}->set_node();
		$p->{Location}{Continent}{Link} = "http://www.mpi.nl/IMDI/Schema/Continents.xml";
		$p->{Location}{Continent}{Type} = "OpenVocabulary";
		$p->{Location}{Country}->set_node();
		$p->{Location}{Country}{Link} = "http://www.mpi.nl/IMDI/Schema/Countries.xml";
		$p->{Location}{Country}{Type} = "ClosedVocabulary";
	}
	
	# ContentType
	my $test;
	for (my $i = 0; $i < scalar @{$types}; $i++){
		$p->{ContentType}[$i]->content($types->[$i][0]);
	}
	
	# Format
	if ($info->[9]){
		$p->{Format}{Text}->content($info->[9]);
	}
	else {
		$p->{Format}->set_node();
	}
	
	# Quality
	$p->{Quality}->set_node();
	
	# Smallest Annotation Unit
	$p->{SmallestAnnotationUnit}->set_node();
	
	# Applications
	if ($info->[24]){
		$p->{Applications}->content($info->[24]);
	}
	else {
		$p->{Applications}->set_node();
	}
	
	# Date
	$p->{Date}->set_node();
	my @date;
	if ($info->[7]){
		push @date, $info->[7];
	}
	if ($info->[8]){
		push @date, $info->[8];
	}
	if (@date){
		$p->{Date}->content(join('/', @date));
	}

	# Project
	if ($info->[25]){
		$p->{Project}{Name}->content($info->[25]);
		$p->{Project}{Title}->content($info->[25]);
	}
	else {
		$p->{Project}->set_node();
		$p->{Project}{Name}->set_node();
		$p->{Project}{Title}->set_node();
	}
	
	$p->{Project}{Id}->set_node();
	$p->{Project}{Contact}->set_node();
	
	# Publisher (institution/organisation name)
	if (@{$inst}){
		foreach my $publ (@{$inst}){
			$p->{Publisher}->content(join(', ', @{$publ}));
		}
	}
	elsif ($info->[5]){
		$p->{Publisher}->content($info->[5]);
	}
	else {
		$p->{Publisher}->set_node();
	}
	
	# Author
	$p->{Author}->set_node();
	
	# Size - decision with Dieter: will contain both collection and lexicon size with respective prefix and ; as delimiter
	my $size;
	if ($info->[26]){
		$info->[26] =~ s/;/,/g;
		$size = "Collection: " . $info->[26];
	}
	if ($info->[34]){
		$info->[34] =~ s/;/,/g;
		if ($size){
			$size .= ";"
		}
		$size .= "Lexicon: " . $info->[34];
	}
	if ($size){
		$p->{Size}->content($size)
	}
	else {
		$p->{Size}->set_node();
	}
	
	# Distribution Form
	if ($info->[27]){
		$p->{DistributionForm}->content($info->[27]);
	}
	else {
		$p->{DistributionForm}->set_node();	
	}

	# Access
	if ($info->[13]){
		$p->{Access}{Availability}->content("available on the internet");
	}
	else {
		$p->{Access}{Availability}->set_node();	
	}
	$p->{Access}{Date}->set_node();
	$p->{Access}{Owner}->set_node();
	$p->{Access}{Publisher}->set_node();
	$p->{Access}{Contact}->set_node();
	
	# Pricing
	$p->{Pricing}->set_node();
	
	# Contact Person - optional
	if ($info->[6]){
		$p->{ContactPerson}->content($info->[6]);
	}
	
	# Reference Link - optional
	if ($info->[12] && !($info->[36] =~ m/field_reference_link_url/g)){
		$p->{ReferenceLink}->content($info->[12]);
	}
	
	# Metadata Link - optional
	if ($info->[10] && !($info->[36] =~ m/field_metadata_link_url/g)){
		$p->{MetadataLink}->content($info->[10]);
	}
	
	# Publications - optional
	if ($info->[11]){
		$p->{Publications}->content($info->[11]);
	}
	
	# Key-value pairs - all optional
	# Node ID
	my $i = 0;
	$p->{Keys}{Key}[$i]{Name} = "NodeId";
	$p->{Keys}{Key}[$i]->content($info->[0]);
	$i++;
	
	# Version ID
	$p->{Keys}{Key}[$i]{Name} = "VersionId";
	$p->{Keys}{Key}[$i]->content($info->[1]);
	$i++;
	
	# Latitude & Longitude
	if ($geocoords){
		$p->{Keys}{Key}[$i]{Name} = "Latitude";
		$p->{Keys}{Key}[$i]->content($geocoords->[0][0]);
		$i++;
		$p->{Keys}{Key}[$i]{Name} = "Longitude";
		$p->{Keys}{Key}[$i]->content($geocoords->[0][1]);
		$i++;
	}
	
	# Other languages - no way to include that in proper language elements
	if ($info->[3]){
		$p->{Keys}{Key}[$i]{Name} = "OtherLanguages";
		$p->{Keys}{Key}[$i]->content($info->[3]);
		$i++;
	}
	
	# Intellectual Property Rights Ethical Reference
	if ($info->[14]){
		$p->{Keys}{Key}[$i]{Name} = "IPREthicalReference";
		$p->{Keys}{Key}[$i]->content($info->[14]);
		$i++;
	}
	
	# Intellectual Property Rights Legal Reference
	if ($info->[15]){
		$p->{Keys}{Key}[$i]{Name} = "IPRLegalReference";
		$p->{Keys}{Key}[$i]->content($info->[15]);
		$i++;
	}	
	
	# Intellectual Property Rights License Type
	if ($info->[16]){
		$p->{Keys}{Key}[$i]{Name} = "IPRLicenseType";
		$p->{Keys}{Key}[$i]->content($info->[16]);
		$i++;
	}	
	
	# Intellectual Property Rights Description
	if ($info->[17]){
		$p->{Keys}{Key}[$i]{Name} = "IPRDescription";
		$p->{Keys}{Key}[$i]->content($info->[17]);
		$i++;
	}
	
	# Intellectual Property Rights Contact Person
	if ($info->[18]){
		$p->{Keys}{Key}[$i]{Name} = "IPRContactPerson";
		$p->{Keys}{Key}[$i]->content($info->[18]);
		$i++;
	}
	
	# Collection Longterm preservation by 
	if ($info->[19]){
		$p->{Keys}{Key}[$i]{Name} = "CollectionLongtermPreservationBy";
		$p->{Keys}{Key}[$i]->content($info->[19]);
		$i++;
	}
	
	# Collection Location
	if ($info->[20]){
		$p->{Keys}{Key}[$i]{Name}= "CollectionLocation";
		$p->{Keys}{Key}[$i]->content($info->[20]);
		$i++;
	}
	
	# Collection Content Type
	if ($info->[21]){
		$p->{Keys}{Key}[$i]{Name} = "CollectionContentType";
		$p->{Keys}{Key}[$i]->content($info->[21]);
		$i++;
	}	
	
	# Collection Format Detailed
	if ($info->[22]){
		$p->{Keys}{Key}[$i]{Name} = "CollectionFormatDetailed";
		$p->{Keys}{Key}[$i]->content($info->[22]);
		$i++;
	}
	
	# Collection Quality
	if ($info->[23]){
		$p->{Keys}{Key}[$i]{Name} = "CollectionQuality";
		$p->{Keys}{Key}[$i]->content($info->[23]);
		$i++;
	}	
	
	# Collection Access
	if ($info->[28]){
		$p->{Keys}{Key}[$i]{Name} = "CollectionAccess";
		$p->{Keys}{Key}[$i]->content($info->[24]);
		$i++;
	}
	
	# Collection Source
	if ($info->[29]){
		$p->{Keys}{Key}[$i]{Name} = "CollectionSource";
		$p->{Keys}{Key}[$i]->content($info->[25]);
		$i++;
	}	
	
	# Lexicon Date
	if ($info->[30]){
		$p->{Keys}{Key}[$i]{Name} = "LexiconDate";
		$p->{Keys}{Key}[$i]->content($info->[30]);
		$i++;
	}		
	
	# Lexicon Type
	if ($info->[31]){
		$p->{Keys}{Key}{Name} = "LexiconType";
		$p->{Keys}{Key}->content($info->[31]);
		$i++;
	}	
	
	# Lexicon Format Detailed
	if ($info->[32]){
		$p->{Keys}{Key}{Name} = "LexiconFormatDetailed";
		$p->{Keys}{Key}->content($info->[32]);
		$i++;
	}	
	
	# Lexicon Schema Reference
	if ($info->[33] && !($info->[36] =~ m/field_schema_reference_value/g)){
		$p->{Keys}{Key}{Name} = "LexiconSchemaReference";
		$p->{Keys}{Key}->content($info->[33]);
		$i++;
	}	
	
	# Lexicon Access
	if ($info->[35]){
		$p->{Keys}{Key}{Name} = "LexiconAccess";
		$p->{Keys}{Key}->content($info->[35]);
		$i++;
	}		
	
	# filename clarin-(nid)-(vid).imdi
	my $filename = "clarin-catalogue-" . $info->[0] . "-" . $info->[1] . ".imdi";
	printFile(($filepath . $filename), $p->data());
	return makeParentCorpus($filepath, $filename, $p, $baseFile);
}

###############################
# Creates the parent corpus node of the catalogue file and 
#
# Arguments: filepath to catalogue file, xml of the catalogue file
# Returns: nothing
###############################

sub	makeParentCorpus{
	my $filepath = shift;
	my $filename = shift;
	my $xml = shift;
	my $baseFile = shift;
	
	my $corpus = makeXmlHeader($baseFile, "Corpus");
	$corpus->{CatalogueLink} = $filename;
	$corpus->{Name}->content($xml->{Name}->content);
	$corpus->{Title}->content($xml->{Title}->content);
	$corpus->{Description}->set_node();
	
	$filename =~ s/catalogue/corpus/g;
	printFile(($filepath . $filename), $corpus->data());
	return $filename, $corpus->{Name}->content;
}

###############################
# Makes the header of the Corpus or Catalogue XML object
#
# Arguments: 
# - template file (required because XML Smart does not set encoding to UTF-8 unless the previous file said so), 
# - imdi type (Corpus, Catalogue; will be used as element name, so should be written exactly the way the element name has to be)
# Returns: XML object pointing to Catalogue/Corpus element in the XML tree
###############################

sub makeXmlHeader{
	my $startfile = shift;
	my $imditype = shift;
	
	my $xml = XML::Smart->new($startfile);
	my $xml = $xml->{METATRANSCRIPT};

	# filling attributes of METATRANSCRIPT
	$xml->{xmlns} = "http://www.mpi.nl/IMDI/Schema/IMDI";
	$xml->{'xmlns:xsi'} = "http://www.w3.org/2001/XMLSchema-instance";
	$xml->{Date} = getTodayDate();
	$xml->{FormatId} = "IMDI 3.0";
	$xml->{Originator} = "admin";
	$xml->{Type} = uc($imditype); 
	$xml->{Version} = "12";
	$xml->{'xsi:schemaLocation'} = "http://www.mpi.nl/IMDI/Schema/IMDI ./IMDI_3.0.xsd";	
	# History
	$xml->{History}->content("CLARIN to IMDI, DATE: " . getTodayDate());
	return $xml->{$imditype};
}




###############################
# Prints the array reference, can be used at different stages 
# in the script to check whether a certain function was executed 
# on the array ref properly
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
# Prints the array reference to a file
#
# Arguments: array ref of file matrix, file path for output file
# Returns: nothing
###############################

sub printFile{
	my $path = shift @_;
	my $str = shift @_;

	$str =~ s/<\?meta name="GENERATOR" content="XML::Smart\/1\.6\.9 Perl\/5\.008008 \[linux\]" \?>\n//g;
	$str =~ s/&amp;#/&#/g;
	
	$path = ">" . $path;
	open(OUT, $path) or die "$!"; 
	print OUT $str;
	close(OUT);
}

###############################
# Tests against the continent list specified in http://www.mpi.nl/IMDI/Schema/Continents.xml
#
# Arguments: region name from LL db info
# Returns: continent name or "Unknown"
###############################

sub testIsoContinents{
	my $reg = shift @_;

	foreach my $c ("Africa", "Asia", "Europe", "Australia", "Oceania", "North-America", "Middle-America", "South-America"){
		if ($reg eq $c){
			return $reg;
		}
	}
	
	return "Unknown";
}

