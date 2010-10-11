#!/bin/env python

# Prints an HTML list of all components and profiles in the CLARIN component registry
# Feedback: Dieter Van Uytvanck, dietuyt@mpi.nl

from urllib import urlopen

try:
        import xml.etree.ElementTree as ElementTree # in python >=2.5
except ImportError:
        from elementtree import ElementTree

def main():
	print "<html><body>"
	printtable("Profiles", "http://catalog.clarin.eu/ds/ComponentRegistry/rest/registry/profiles")
	printtable("Components", "http://catalog.clarin.eu/ds/ComponentRegistry/rest/registry/components")
	print "</body></html>"
	
def printtable(title, url):
	root = ElementTree.parse(urlopen(url)).getroot()
	compList = root.findall("*")
	print "<h1>%s</h1>\n<table>" % title
	print "<tr>"
	for h in ["Name", "Description", "Domain", "Creator"]:
		print "<td><b>%s</b></td>" % h
	print "</tr>"
	for c in compList:
		if title == "Components" and c.find("groupName") != None:
			if  "clarin-nl" in c.find("groupName").text.lower():
				printRow(c)
		elif title == "Profiles":
			printRow(c)
		#else:
			#print "<td></td>"
	print "</table>"
	
	
def printRow(c):
	print "<tr>"
	print "\t<td><a href='%s'>%s</a></td>" % (c.find("{http://www.w3.org/1999/xlink}href").text, c.find("name").text)
	for i in ["description", "domainName", "creatorName"]:
		if c.find(i) != None:
			print "\t<td>%s</td>" % c.find(i).text
		else:
			print "<td></td>"
	print "</tr>"
	
main()