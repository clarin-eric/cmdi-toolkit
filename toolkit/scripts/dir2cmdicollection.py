#!/usr/bin/env python

# generates CMDI collection file hierarchy for collections of CMDI records
# support and questions: Dieter Van Uytvanck <dietuyt@mpi.nl>
# rework by Matej id@vronk.net : 
# 	- already filling ResourceRef with handles read from the MdSelfLink of the mdrecords
#   - also reading ProviderURL-file and filling as ID in the basic collection-profile
#   - does NOT add IsPartOf-elements yet

import os, datetime
from string import Template

target_dir = "_corpusstructure/"

def main():
	rootList = []
	if not os.path.isdir(target_dir):
		os.mkdir(target_dir)
	for root, dirs, files in os.walk(os.getcwd()):
		startpath = os.getcwd()		
		for d in dirs:
			if d == "0":
				rootList.append(generate_branch(root, dirs))
	writeCollection(rootList, target_dir + "collection_root.cmdi", "olac-root")
		
def generate_branch(root, dirs):
	collectionName = os.path.relpath(root)
	collectionFile = "_corpusstructure/collection_%s.cmdi" % collectionName
	
	dirs.sort()
	collectionList = []	
	for d in dirs:
		fullpath = os.path.join(root, d)
		for file in os.listdir(fullpath):
			if ".cmdi" in file:
				newFile = os.path.relpath(os.path.join(fullpath,file))
				collectionList.append(newFile)		
	collid = writeCollection(collectionList, collectionFile, collectionName)
	print "genbranch:" + collid
	return collid


def writeCollection(collectionList, collectionFile, collectionName):

	resourceTemplate = Template('<ResourceProxy id="$idname"><ResourceType>Metadata</ResourceType><ResourceRef>$idx</ResourceRef></ResourceProxy>')

	outstring = Template("""<?xml version="1.0" encoding="UTF-8"?>
<CMD xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
    xsi:schemaLocation="http://www.clarin.eu/cmd http://catalog.clarin.eu/ds/ComponentRegistry/rest/registry/profiles/clarin.eu:cr1:p_1284723009187/xsd">
    <Header>
        <MdCreator>dir2cmdicollection.py</MdCreator>
        <MdCreationDate>$date</MdCreationDate>
        <MdSelfLink>$selflink</MdSelfLink>
        <MdProfile>clarin.eu:cr1:p_1284723009187</MdProfile>
    </Header>
    <Resources>
        <ResourceProxyList>$rp
        </ResourceProxyList>
        <JournalFileProxyList/>
        <ResourceRelationList/>
    </Resources>    
    <Components>
        <collection>
        	<GeneralInfo>
          	<Name>$name</Name>
        		<ID>$url</ID>
        	</GeneralInfo>
        </collection>
    </Components>
</CMD>""")

	resourceProxies = ""
	collectionList.sort()		
	if os.path.isfile(collectionName + "/ProviderURL"):
		urlf = open(collectionName + "/ProviderURL", 'r')
		url = urlf.readline()
	else: 
	  url ="?"
	name = "OLAC: " + collectionName.replace("_", " ")
	idx = ""
	for item in collectionList:
		# trying to restore the original id (which is in the MdSelfLink
		if os.path.isfile(item):
				for line in open(item):
					if "<MdSelfLink>" in line:
 						#  WARNING! rocket science employed here !
						idx = line.replace("<MdSelfLink>","").replace("</MdSelfLink>","").strip() 
						break
		else:
			 idx = item
		#idx = item.replace(".xml.cmdi","").replace("_", ":",1)[::-1].replace("_", ":",1)[::-1].replace("_", "-")
		resourceProxies += "\n" + resourceTemplate.substitute(idname = idx.replace(".","_").replace("/","_"), idx = idx)
	if collectionName=="olac-root":
		collidx = "olac-root"
	else:
		# print "idx:" + idx
		if idx!="":
			collidx = idx[:idx.rfind(":")] # this is just a hack to derive the collection-id from the id of the collection-item (stripping the running number)
		else:
			collidx = "olac:" + collectionName
	print collidx 
	outfile = outstring.substitute(date= datetime.datetime.now().strftime("%Y-%m-%d"), selflink=collidx, rp=resourceProxies,url=url, name=name)
	f = open(collectionFile, 'w')	
	f.write(outfile)
	f.close()
	
	print collectionFile
	return collidx

main()
