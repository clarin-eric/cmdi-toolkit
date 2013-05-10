#!/usr/bin/env python

# converts the CSV from the LRT inventory to nice and clean CMDI
# Dieter says: I deny the existance of this script!

import csv, datetime, pdb, sys, traceback, urllib, xml.etree.ElementTree as ElementTree
from curses.ascii import ascii

if sys.version_info < (2, 7) or sys.version_info >= (3, 0):
    sys.stderr.write("WARNING: this script was only tested with Python version 2.7.3! You are running version " + str(sys.version_info[1]) + "." + str(sys.version_info[2]) + " instead.\n")

class CmdiFile :
    def __init__(self, nodeId) :
        template            = open("cmdi-lrt-template.xml").read()
        self.nodeId         = nodeId
        self.xmlTree        = ElementTree.ElementTree(ElementTree.fromstring(template))
        self.parentmap      = dict((c, p) for p in self.xmlTree.getiterator() for c in p)
        self.current_date   = datetime.datetime.now().strftime("%Y-%m-%d")
        self.fillElement("//MdCreationDate", self.current_date)
        self.fillElement("//MdSelfLink", "http://lrt.clarin.eu/node/%s" % nodeId)

    def fillElement(self, XPath, value) :
        try :
            self.xmlTree.find(XPath).text = value.strip()
        except :
            print "Error in filling element " + XPath
            print traceback.format_exc()

            pdb.set_trace()
        

    def fillOptionalElement(self, XPath, value) :
        try :
            result = self.fillElement(XPath, value)
        except :
            print "Error in filling optional element " + XPath
            print traceback.format_exc()

            pdb.set_trace()
        else :
            return result

        ### Conceptual code that should remove optional elements if they are being filled with empty strings.
        # optional_element_parent_XPath   = XPath + "/.." 
        # optional_element_parent         = self.xmlTree.find(optional_element_parent_XPath)
        # optional_element                = self.xmlTree.find(XPath)

        # try :
        #     assert(optional_element_parent is not None)
        #     assert(optional_element is not None)
        # except :
        #     import pdb
        #     pdb.set_trace()

        # value = str(value).strip()
        # if len(value) > 1 :
        #     optional_element.text   = value
        # else :
        #     optional_element_parent.remove(optional_element)

    def fillMultipleElement(self, elementname, xpath, values):
        # fill in the already existing element
        if (values[0]):
            self.fillElement(xpath, values[0])

        element = self.xmlTree.find(xpath)
        parent = self.parentmap[element]
        position = parent.getchildren().index(element)

        # then add siblings for the other elements
        for value in values[1:]:
            if value:
                # create new sibling of xpath (elementname) = value
                position += 1
                newElement = ElementTree.Element(elementname)
                newElement.text = value.strip()
                parent.insert(position, newElement)

    def removeEmptyNodes(self):
        # we maybe added some elements so need to recalculate the parentmap
        self.parentmap = dict((c, p) for p in self.xmlTree.getiterator() for c in p)

        removeList = ["ResourceType", "BeginYearResourceCreation", "FinalizationYearResourceCreation", "Institute", \
                      "DistributionType", "NonCommercialUsageOnly", "UsageReportRequired", "ModificationsRequireRedeposition", "WorkingLanguages", "Date"]
        for r in removeList:
            results = self.xmlTree.findall("//%s" % r)
            for res in results:
                if not res.text:
                    parentNode = self.parentmap[res]
                    parentNode.remove(res)

    def serialize(self):
        self.removeEmptyNodes()
        #print ElementTree.tostring(self.xmlTree.getroot())
        filename            = "lrt-%s.cmdi" % self.nodeId
        self.xmlTree.write(filename, encoding = "utf-8", xml_declaration = True)
        f                   = open(filename, 'r+' )
        content             = f.read().replace('<CMD', '<CMD xmlns="http://www.clarin.eu/cmd/"')
        f.close()
        f                   = open(filename, 'w' )
        f.write(content)
        f.close

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

    def addLanguages(self, isoList, languages, iso639Type = 3, xpath = "//LrtCommon/Languages"):
        languagesNode = self.xmlTree.find(xpath)
        languageList = [l.strip() for l in languages.split("||")]
        for language in languageList:
            if language and not language == "-- language not in list --":
                newLanguageNode = ElementTree.Element("ISO639")
                newCodeNode = ElementTree.Element("iso-639-%s-code" % iso639Type)
                keyLang = language.encode("utf-8")
                newCodeNode.text = isoList[keyLang]
                newLanguageNode.append(newCodeNode)
                languagesNode.append(newLanguageNode)


    def addResourceType(self, types, record, isoList):
            typeList = [t.strip() for t in types.split("||")]
            self.fillMultipleElement("ResourceType", "//LrtCommon/ResourceType", typeList)
            typeList = frozenset(typeList)

            collectionList  = frozenset(("Spoken Corpus", "Written Corpus", "Multimodal Corpus", "Aligned Corpus", "Treebank", "N-Gram Model",))
            lexiconList     = frozenset(("Grammar", "Lexicon / Knowledge Source", "Terminological Resource",))
           
            if typeList.intersection(collectionList):
                self.addCollectionDetails(record, isoList)
            if typeList.intersection(lexiconList):
                self.addLexiconDetails(record, isoList)
            if "Web Service" in typeList:
                #pdb.set_trace()
                self.addServiceDetails(record)

    def addCollectionDetails(self, record, isoList):
        LrtCollectionDetails_XPath  = "//LrtInventoryResource/LrtCollectionDetails"


        self.fillOptionalElement(LrtCollectionDetails_XPath + "/LongTermPreservationBy",    
                                 record["field_longterm_preservation"])
        self.fillOptionalElement(LrtCollectionDetails_XPath + "/Location",                  
                                 record["field_location_0"])
        self.fillOptionalElement(LrtCollectionDetails_XPath + "/ContentType",               
                                 record["field_content_type"])
        self.fillOptionalElement(LrtCollectionDetails_XPath + "/FormatDetailed",            
                                 record["field_format_detailed"])
        self.fillOptionalElement(LrtCollectionDetails_XPath + "/Quality",                   
                                 record["field_quality"])
        self.fillOptionalElement(LrtCollectionDetails_XPath + "/Applications",              
                                 record["field_applications"])
        self.fillOptionalElement(LrtCollectionDetails_XPath + "/Size",                      
                                 record["field_size"])
        self.fillOptionalElement(LrtCollectionDetails_XPath + "/DistributionForm",          
                                 record["field_distribution_form"])
        self.fillOptionalElement(LrtCollectionDetails_XPath + "/Size",                      
                                 record["field_size"])
        self.fillOptionalElement(LrtCollectionDetails_XPath + "/Access",                    
                                 record["field_access"])
        self.fillOptionalElement(LrtCollectionDetails_XPath + "/Source",                    
                                 record["field_source_0"])

        # ok - this can be done in a cleaner way
        self.addLanguages(isoList, 
                          record["field_working_languages"], 
                          1, 
                          LrtCollectionDetails_XPath + "/WorkingLanguages")

    def addLexiconDetails(self, record, isoList):
        LrtLexiconDetails_XPath = "//LrtInventoryResource/LrtLexiconDetails"

        self.fillOptionalElement(LrtLexiconDetails_XPath + "/Date",                         
                                 record["field_date_0"])
        self.fillOptionalElement(LrtLexiconDetails_XPath + "/Type",                         
                                 record["field_type"])
        self.fillOptionalElement(LrtLexiconDetails_XPath + "/FormatDetailed",               
                                 record["field_format_detailed_1"])
        self.fillOptionalElement(LrtLexiconDetails_XPath + "/SchemaReference",              
                                 record["field_schema_reference"])
        self.fillOptionalElement(LrtLexiconDetails_XPath + "/Size",                         
                                 record["field_size_0"])
        self.fillOptionalElement(LrtLexiconDetails_XPath + "/Access",                       
                                 record["field_access_1"])
        self.addLanguages(isoList, 
                          record["field_working_languages_0"], 
                          1, 
                          LrtLexiconDetails_XPath + "/WorkingLanguages")

    def addServiceDetails(self, record):

        #pdb.set_trace()
        LrtLexiconDetails_XPath  = "//LrtInventoryResource/LrtServiceDetails"

        if str(record["field_date_0"]).strip() == '' :
            service_date = self.current_date
        else :
            service_date = record["field_date_0"] 

        self.fillElement(LrtLexiconDetails_XPath + "/Date",
                         service_date)

    def addResourceProxy(self, link) :
        template = '''<ResourceProxy id="reflink">
                <ResourceType>Resource</ResourceType>
                <ResourceRef></ResourceRef>
            </ResourceProxy>'''
        partTree = ElementTree.XML(template)
        parent = self.xmlTree.find(".//ResourceProxyList")
        parent.append(partTree)

        # and now fill it
        self.fillElement("//ResourceProxy/ResourceRef", link)

    def addTags(self, tags_string) :
        tags_parent_XPath               = "//LrtInventoryResource" # One could use "/..", but that is unnecessary and can lead to mistakes.
        tags_XML_element                = self.xmlTree.find("//LrtInventoryResource/tags")
        assert(tags_XML_element is not None)

        tags = filter(None, tags_string.split(","))
        if len(tags) > 0 :
            # Remove whitespace left and right to tag values
            tags                        = list(map(unicode.strip, tags)) # X- Python 3 incompatible
            # Remove empty strings from tags list.
            tags                        = list(filter(None, tags))

            for tag in tags :
                tag_XML_element         = ElementTree.Element('tag')
                tag_XML_element.text    = tag
                tags_XML_element.append(tag_XML_element)
        else :
            tags_parent_element         = self.xmlTree.find(tags_parent_XPath)
            tags_parent_element.remove(tags_XML_element)

def addChildNode(parent, tag, content) :
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
    csvFile = csv.reader(urllib.urlopen("http://lrt.clarin.eu/export_resources").readlines())
    #csvFile = csv.reader(urllib.urlopen("resources.csv").readlines())
    #csvFile =[l.decode('utf-8') for l in rawCsvFile]


    linenr = 0
    newDict = dict()
    for l in csvFile:
        if linenr == 0:
            fieldList = parseFirstLine(l)
        else:
            newDict[linenr] = dict()
            colnr = 0
            for field in fieldList:
                newDict[linenr][fieldList[colnr].replace(" ", "_").decode('utf-8')] = l[colnr].decode('utf-8')
                colnr += 1
        linenr += 1
    return newDict

def loadCsv(filename):
    csvFile = csv.reader(urllib.urlopen(filename).readlines())
    dictionary = dict()
    for l in csvFile:
        dictionary[l[1]] = l[0]

    return dictionary

# only to be used in case we use the namespace, but as it is causing a lot of extra coding we just add an xmlns attribute in the end and ignore it
#    def fixXpath(self, xpath):
#        if xpath[0:2] == "//":
#            xpath = "//{http://www.clarin.eu/cmd/}" + xpath[2:].replace("/", "/{http://www.clarin.eu/cmd/}")
#        else:
#            xpath = xpath.replace("/", "/{http://www.clarin.eu/cmd/}")
#        return xpath

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
        cmdi.fillElement("//LrtCommon/ReadilyAvailable", record["field_resource_available"].replace("Yes", "true").replace("No", "false"))
        cmdi.fillElement("//LrtCommon/ReferenceLink", record["field_reference_link"])

        cmdi.fillElement("//LrtDistributionClassification/DistributionType", record["distribution_type"])
        cmdi.fillElement("//LrtDistributionClassification/ModificationsRequireRedeposition", record["modifications_require_redeposition"].replace("1", "true").replace("0","false"))
        cmdi.fillElement("//LrtDistributionClassification/NonCommercialUsageOnly", record["non-commercial_usage_only"].replace("1", "true").replace("0", "false"))
        cmdi.fillElement("//LrtDistributionClassification/UsageReportRequired", record["usage_report_required"].replace("1", "true").replace("0", "false"))
        cmdi.fillElement("//LrtDistributionClassification/OtherDistributionRestrictions", record["other_distribution_restrictions"])

        cmdi.fillElement("//LrtIPR/EthicalReference", record["field_ethical_reference"])
        cmdi.fillElement("//LrtIPR/LegalReference", record["field_legal_reference"])
        cmdi.fillElement("//LrtIPR/LicenseType", record["field_license_type"])
        cmdi.fillElement("//LrtIPR/Description", record["field_description_0"])
        cmdi.fillElement("//LrtIPR/ContactPerson", record["field_contact_person"])

        # add a ResourceProxy for ReferenceLink
        if "http" in record["field_reference_link"]:
            cmdi.addResourceProxy(record["field_reference_link"])

        # more sophisticated (dirty) tricks needed
        cmdi.addFormats(record["field_format"])

        orgList = ""
        for i in range(1,5):
            orgList += record["org" + str(i)] + ";"
        cmdi.addInstitutes(orgList + record["field_institute"])

        cmdi.addCountries(countryList, record["field_country"])

        cmdi.addLanguages(iso6393List, record["field_languages"])

        cmdi.addResourceType(record["field_resource_type"], record, iso6391List)

        cmdi.addTags(record['tags']);

        cmdi.serialize()

main()
