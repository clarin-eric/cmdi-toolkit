#!/usr/bin/env python

# generates CMDI collection file hierarchy for collections of CMDI records
# support and questions: Dieter Van Uytvanck <dietuyt@mpi.nl>

import os, datetime
from string import Template

def main():
	rootList = []
	for root, dirs, files in os.walk(os.getcwd()):
		startpath = os.getcwd()		
		for d in dirs:
			if d == "0":
				rootList.append(generate_branch(root, dirs))
	writeCollection(rootList, "collection_root.cmdi")
		
def generate_branch(root, dirs):
	collectionFile = "collection_%s.cmdi" % os.path.relpath(root)
	dirs.sort()
	collectionList = []	
	for d in dirs:
		fullpath = os.path.join(root, d)
		for file in os.listdir(fullpath):
			if ".cmdi" in file:
				newFile = os.path.relpath(os.path.join(fullpath,file))
				collectionList.append(newFile)		
	writeCollection(collectionList, collectionFile)
	return collectionFile


def writeCollection(collectionList, collectionFile):

	resourceTemplate = Template('<ResourceProxy id="$idname"><ResourceType>Metadata</ResourceType><ResourceRef>$filename</ResourceRef></ResourceProxy>')

	outstring = Template("""<?xml version="1.0" encoding="UTF-8"?>
<CMD xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
    xsi:schemaLocation="http://www.clarin.eu/cmd http://catalog.clarin.eu/ds/ComponentRegistry/rest/registry/profiles/clarin.eu:cr1:p_1271859438236/xsd">
    <Header>
        <MdCreator>dir2cmdicollection.py</MdCreator>
        <MdCreationDate>$date</MdCreationDate>
        <MdSelfLink>$selflink</MdSelfLink>
        <MdProfile>clarin.eu:cr1:p_1271859438236</MdProfile>
    </Header>
    <Resources>
        <ResourceProxyList>$rp
        </ResourceProxyList>
        <JournalFileProxyList/>
        <ResourceRelationList/>
    </Resources>
    <Components>
        <olac></olac>
    </Components>
</CMD>""")

	resourceProxies = ""
	collectionList.sort()	
	for item in collectionList:
		resourceProxies += "\n" + resourceTemplate.substitute(idname = item.replace("/", "_").replace("\\", "_"), filename = item)
	outfile = outstring.substitute(date= datetime.datetime.now().strftime("%Y-%m-%d"), selflink=collectionFile, rp=resourceProxies)
	f = open(collectionFile, 'w')
	f.write(outfile)
	f.close()
	print collectionFile

main()
