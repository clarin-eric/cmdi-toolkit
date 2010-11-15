#!/usr/bin/env python

# converts the CSV from the LRT inventory to nice and clean CMDI
# Dieter says: I deny the existance of this script! 

import urllib, csv, datetime, xml.etree.ElementTree as ElementTree

class CmdiFile:
    def __init__(self, nodeId):
        template = open("cmdi-lrt-template.xml").read()
        self.nodeId = nodeId
        self.xmlTree = ElementTree.ElementTree(ElementTree.fromstring(template))
        # create dict with links to parent node for each node (= key)
        self.parentmap = dict((c, p) for p in self.xmlTree.getiterator() for c in p)
        self.fillElement("//MdCreationDate", datetime.datetime.now().strftime("%Y-%m-%d"))
        self.fillElement("//MdSelfLink", "clarin.eu:lrt:%s" % nodeId)

    def fillElement(self, xpath, value):
        #print "fill %s with %s" % (xpath, value)
        self.xmlTree.find(xpath).text = value.strip() 
        
    def fillMultipleElement(self, elementname, xpath, values):
        # fill in the already existing element
        #print values
        if (values[0]):
            #print "first one", values[0]
            #print values[0]
            self.fillElement(xpath, values[0])
            #print "fill %s with %s" % (xpath, values[0])
        #print
        
        element = self.xmlTree.find(xpath)
        parent = self.parentmap[element]
        position = parent.getchildren().index(element)
        
        # then add siblings for the other elements
        for value in values[1:]:
            if value:
                # create new sibling of xpath (elementname) = value
                #print value
                #print "next one", value
                position += 1
                newElement = ElementTree.Element(elementname)
                newElement.text = value.strip()
                parent.insert(position, newElement)
    
    def serialize(self): 
        filename = "lrt-%s.cmdi" % self.nodeId
        self.xmlTree.write(filename, encoding="utf-8")
        
    def addFormats(self, format):
        if ";" in format or "," in format:
            if ";" in format:
                formatItems = format.split(";") 
            else:
                formatItems = format.split(",")
            self.fillMultipleElement("Format", "//LrtCommon/Format", formatItems)
        else:
            self.fillElement("//LrtCommon/Format", format)
    
    def addInstitutes(self, institute):
        if ";" in institute:
                items = institute.split(";") 
                uniqueItems = set(items) # filter out double items
                items = [i for i in uniqueItems] # convert set back to a list
                #print items
                 
                self.fillMultipleElement("Institute", "//LrtCommon/Institute", items)
    
    def addCountries(self, countryList, countries):
        countriesNode = self.xmlTree.find("//LrtCommon/Countries")
        goodList = [c.strip() for c in countries.split("||")]
        for country in goodList:
            if country:
                newCountryNode = ElementTree.Element("Country")
                newCodeNode = ElementTree.Element("Code")
                newCodeNode.text = countryList[country]
                newCountryNode.append(newCodeNode)
                countriesNode.append(newCountryNode)
        
    def addLanguages(self, isoList, languages, iso639Type=3, xpath="//LrtCommon/Languages"):
        languagesNode = self.xmlTree.find(xpath)
        languageList = [l.strip() for l in languages.split("||")]
        for language in languageList:
            if language and not language == "-- language not in list --":
                newLanguageNode = ElementTree.Element("ISO639")
                newCodeNode = ElementTree.Element("iso-639-%s-code" % iso639Type)
                newCodeNode.text = isoList[language]
                newLanguageNode.append(newCodeNode)
                languagesNode.append(newLanguageNode)
                    
                    
    def addResourceType(self, types, record, isoList):
            typeList = [t.strip() for t in types.split("||")]
            self.fillMultipleElement("ResourceType", "//LrtCommon/ResourceType", typeList)
            
            collectionList = ["Written Corpus","Multimodal Corpus","Aligned Corpus","Treebank","N-Gram Model"]
            lexiconList = ["Lexicon / Knowledge Source","Terminological Resource"]
            
            if set(typeList).intersection(set(collectionList)):
                self.addCollectionDetails(record, isoList)
            if set(typeList).intersection(set(lexiconList)):
                self.addLexiconDetails(record, isoList)
            #if "Web Service" in typeList:
            #    self.addServiceDetails(record)    
            
    def addCollectionDetails(self, record, isoList):
        # add the relevant XML subtree
        template = '''<LrtCollectionDetails>
                <LongTermPreservationBy />
                <Location />
                <ContentType />
                <FormatDetailed />
                <Quality />
                <Applications />
                <Size />
                <DistributionForm />
                <Access />
                <Source />
                <WorkingLanguages />
            </LrtCollectionDetails>'''
        partTree = ElementTree.fromstring(template)
        parent = self.xmlTree.find("//LrtInventoryResource")
        parent.append(partTree)
        # and now fill it
        self.fillElement("//LrtCollectionDetails/LongTermPreservationBy", record["field_longterm_preservation"])
        self.fillElement("//LrtCollectionDetails/Location", record["field_location_0"])
        self.fillElement("//LrtCollectionDetails/ContentType", record["field_content_type"])
        self.fillElement("//LrtCollectionDetails/FormatDetailed", record["field_format_detailed"])
        self.fillElement("//LrtCollectionDetails/Quality", record["field_quality"])
        self.fillElement("//LrtCollectionDetails/Applications", record["field_applications"])
        self.fillElement("//LrtCollectionDetails/Size", record["field_size"])
        self.fillElement("//LrtCollectionDetails/DistributionForm", record["field_distribution_form"])
        self.fillElement("//LrtCollectionDetails/Size", record["field_size"])
        self.fillElement("//LrtCollectionDetails/Access", record["field_access"])
        self.fillElement("//LrtCollectionDetails/Source", record["field_source_0"])
        
        # ok - this can be done in a cleaner way
        self.addLanguages(isoList, record["field_working_languages"], 1, "//LrtCollectionDetails/WorkingLanguages")
        
        
    
    def addLexiconDetails(self, record, isoList):
        template = '''<LrtLexiconDetails>
                <Date />
                <Type />
                <FormatDetailed />
                <SchemaReference />
                <Size />
                <Access />
                <WorkingLanguages/>
            </LrtLexiconDetails>'''
        partTree = ElementTree.fromstring(template)
        parent = self.xmlTree.find("//LrtInventoryResource")
        parent.append(partTree)
        
        # and now fill it
        self.fillElement("//LrtLexiconDetails/Date", record["field_date_0"])
        self.fillElement("//LrtLexiconDetails/Type", record["field_type"])
        self.fillElement("//LrtLexiconDetails/FormatDetailed", record["field_format_detailed_1"])
        self.fillElement("//LrtLexiconDetails/SchemaReference", record["field_schema_reference"])
        self.fillElement("//LrtLexiconDetails/Size", record["field_size_0"])
        self.fillElement("//LrtLexiconDetails/Access", record["field_access_1"])
        
        self.addLanguages(isoList, record["field_working_languages_0"], 1, "//LrtLexiconDetails/WorkingLanguages")
    
    
    def addServiceDetails(self, record):
        template = '''<LrtServiceDetails>
                <Date />
                <LocationWebservice />
                <InterfaceReference />
                <Input />
                <InputSchemaReference />
                <Output />
                <OutputSchema />
                <DevDescription />
                <Access />
            </LrtServiceDetails>'''
        partTree = ElementTree.fromstring(template)
        parent = self.xmlTree.find("//LrtInventoryResource")
        parent.append(partTree)
        
        # and now fill it
        self.fillElement("//LrtLexiconDetails/Date", record["field_date_0"])
        

def addChildNode(parent, tag, content):
    node = ElementTree.Element(tag)
    node.text = content
    parent.append(node)


def parseFirstLine(l):
    keyList = [l[0].lower()]  
    for key in l[1:]:
        if "(" in key:
            keyList.append(key.split("(")[-1].replace(")", "").lower())
        else:
            keyList.append(key.replace(" ", "_").lower())
    return keyList
    
            
def loadInfo():
    csvFile = csv.reader(urllib.urlopen("http://www.clarin.eu/export_resources").readlines())
    #csvFile = csv.reader(urllib.urlopen("resources.csv").readlines())  
    linenr = 0
    newDict = dict()
    for l in csvFile:
        if linenr == 0:
            fieldList = parseFirstLine(l)
        else:
            newDict[linenr] = dict()
            colnr = 0
            for field in fieldList:
                newDict[linenr][fieldList[colnr].replace(" ", "_")] = l[colnr]
                colnr += 1 
        linenr += 1
    return newDict    

def loadCsv(filename):
    csvFile = csv.reader(urllib.urlopen(filename).readlines())
    dictionary = dict()
    for l in csvFile:
        dictionary[l[1]] = l[0]
    return dictionary


def main():
    infoDict = loadInfo()
    countryList = loadCsv("country_codes.csv")
    iso6393List = loadCsv("639-3-language_codes.csv")
    iso6391List = loadCsv("639-1-language_codes.csv")
    
    for record in infoDict.values():
        print "creating lrt-%s.cmdi" % record["nid"]
        
        cmdi = CmdiFile(record["nid"])
        
        # 1-to-1 fields, easy case
        cmdi.fillElement("//LrtCommon/ResourceName", record["name"])
        cmdi.fillElement("//LrtCommon/Description", record["field_description"])
        cmdi.fillElement("//LrtCommon/ContactPerson", record["field_creator"])
        cmdi.fillElement("//LrtCommon/LanguagesOther", record["field_languages_other"])
        cmdi.fillElement("//LrtCommon/BeginYearResourceCreation", record["field_year"])
        cmdi.fillElement("//LrtCommon/FinalizationYearResourceCreation", record["field_end_creation_date"])
        cmdi.fillElement("//LrtCommon/MetadataLink", record["field_metadata_link"])
        cmdi.fillElement("//LrtCommon/Publications", record["field_publications"])
        cmdi.fillElement("//LrtCommon/ReadilyAvailable", record["field_resource_available"].replace("Yes","true").replace("No","false"))

        cmdi.fillElement("//LrtDistributionClassification/DistributionType", record["distribution_type"])
        cmdi.fillElement("//LrtDistributionClassification/ModificationsRequireRedeposition", record["modifications_require_redeposition"].replace("1","true").replace("0","false"))
        cmdi.fillElement("//LrtDistributionClassification/NonCommercialUsageOnly", record["non-commercial_usage_only"].replace("1","true").replace("0","false"))
        cmdi.fillElement("//LrtDistributionClassification/UsageReportRequired", record["usage_report_required"].replace("1","true").replace("0","false"))
        cmdi.fillElement("//LrtDistributionClassification/OtherDistributionRestrictions", record["other_distribution_restrictions"])
        
        cmdi.fillElement("//LrtIPR/EthicalReference", record["field_ethical_reference"])
        cmdi.fillElement("//LrtIPR/LegalReference", record["field_legal_reference"])
        cmdi.fillElement("//LrtIPR/LicenseType", record["field_license_type"])
        cmdi.fillElement("//LrtIPR/Description", record["field_description_0"])
        cmdi.fillElement("//LrtIPR/ContactPerson", record["field_contact_person"])
        
        # more sophisticated (dirty) tricks needed
        cmdi.addFormats(record["field_format"])

        orgList = ""
        for i in range(1,5):
            orgList += record["org%s" % i] + ";"
        cmdi.addInstitutes(orgList + record["field_institute"])
        
        cmdi.addCountries(countryList, record["field_country"])
        
        cmdi.addLanguages(iso6393List, record["field_languages"])
        
        cmdi.addResourceType(record["field_resource_type"], record, iso6391List)
        
        cmdi.serialize()



main()