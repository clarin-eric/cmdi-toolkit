<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
   xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
   xmlns="http://www.openarchives.org/OAI/2.0/static-repository"
   xmlns:oai="http://www.openarchives.org/OAI/2.0/"
   xmlns:olac="http://www.language-archives.org/OLAC/1.1/"
   xmlns:dc="http://purl.org/dc/elements/1.1/" xmlns:dcterms="http://purl.org/dc/terms/"
   xmlns:ms="http://www.ilsp.gr/META-XMLSchema"
   xsi:schemaLocation="http://www.openarchives.org/OAI/2.0/static-repository 
 http://www.language-archives.org/OLAC/1.1/static-repository.xsd
 http://www.language-archives.org/OLAC/1.1/
 http://www.language-archives.org/OLAC/1.1/olac.xsd
 http://purl.org/dc/elements/1.1/
 http://dublincore.org/schemas/xmls/qdc/2006/01/06/dc.xsd
 http://purl.org/dc/terms/
 http://dublincore.org/schemas/xmls/qdc/2006/01/06/dcterms.xsd">


   <!-- Metashare to OLAC converter by IULA UPF. Change dc:publisher as desired (hardcoded!!!)-->

   <xsl:variable name="lcletters">abcdefghijklmnopqrstuvwxyz</xsl:variable>
   <xsl:variable name="ucletters">ABCDEFGHIJKLMNOPQRSTUVWXYZ</xsl:variable>

   <xsl:output indent="yes" method="xml" version="1.0" encoding="UTF-8"/>
   <xsl:template match="text()"/>

   
   <!-- RESOURCE INFO (common to all resources: dc.title & dc.description & dc.publisher & dc.creator & dc.date dc.rights) -->


   <xsl:template match="ms:resourceInfo">
      <olac:olac
         xsi:schemaLocation="http://www.language-archives.org/OLAC/1.1/
         http://www.language-archives.org/OLAC/1.1/olac.xsd">
         <xsl:apply-templates/>
      </olac:olac>
   </xsl:template>


   <!-- dc.title & dc.description & dc.publisher -->
   <xsl:template match="ms:resourceInfo/ms:identificationInfo">

      <dc:title>
         <xsl:value-of select="./ms:resourceName"/>
      </dc:title>

      <dc:description>
         <xsl:for-each select="./ms:description">
            <xsl:value-of select="normalize-space(.)"/>
            <xsl:text> </xsl:text>
         </xsl:for-each>
      </dc:description>
      
      <dc:publisher>
         <xsl:text>Universitat Pompeu Fabra. Institut Universitari de Lingüística Aplicada (IULA)</xsl:text>
      </dc:publisher>
      
      <dc:identifier xsi:type="dcterms:URI">
         <xsl:value-of select="./ms:identifier"/>
      </dc:identifier>
      
   </xsl:template>


   <!-- dc.creator -->
   <xsl:template
      match="/ms:resourceInfo/ms:resourceCreationInfo/ms:resourceCreator/ms:organizationInfo/ms:organizationName">
      
      <dc:creator>
         <xsl:value-of select="."/>
      </dc:creator>
   </xsl:template>

   <!-- dc.date  -->
   <xsl:template match="/ms:resourceInfo/ms:metadataInfo/ms:metadataCreationDate">
      <dc:date>
         <xsl:value-of select="."/>
      </dc:date>
   </xsl:template>

   <!-- dc.rights- -->
   
   <xsl:template match="ms:resourceInfo/ms:distributionInfo">
      <dc:rights>
         <xsl:choose>
            <xsl:when test="./ms:licenceInfo/ms:licence = 'CC-BY-NC-SA'">
               <xsl:text>This resource is licensed under a Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License (http://creativecommons.org/licenses/by-nc-sa/3.0/)</xsl:text>
            </xsl:when>
            
            <xsl:when test="./ms:licenceInfo/ms:licence = 'CC-BY-SA'">
               <xsl:text>This resource is licensed under a Creative Commons Attribution-ShareAlike 3.0 Unported License (http://creativecommons.org/licenses/by-sa/3.0/)</xsl:text>
            </xsl:when>
            
            <xsl:when test="./ms:licenceInfo/ms:licence = 'AGPL'">
               <xsl:text>This resource is licensed under an Affero General Public License</xsl:text>
            </xsl:when>
            
            <xsl:when test="./ms:licenceInfo/ms:licence = 'GPL'">
               <xsl:text>This resource is licensed under a GNU General Public License version 2.0</xsl:text>
            </xsl:when>
            
            <xsl:when test="./ms:licenceInfo/ms:licence = 'MSCommons-BY-NC-SA'">
               <xsl:text>This resource is licensed under a META-SHARE Commons Attribution-NonCommercial-ShareAlike License (http://www.meta-net.eu/meta-share/meta-share-licenses/META-SHARE%20COMMONS_BYNCSA%20v1.0.pdf)</xsl:text>
            </xsl:when>
            
            <xsl:when test="./ms:licenceInfo/ms:licence = 'GFDL'">
               <xsl:text>This resource is licensed under a GNU Free Documentation License</xsl:text>
            </xsl:when>
            
            <xsl:otherwise>
               <xsl:text>This resource is licensed under a '</xsl:text>
               <xsl:value-of select="./ms:licenceInfo/ms:licence"/>
               <xsl:text>'</xsl:text>
            </xsl:otherwise>
         </xsl:choose>
         
         <xsl:text>. The availability status of the resource is: '</xsl:text>
         <xsl:value-of select="ms:availability"/>
         <xsl:text>'.</xsl:text>
      </dc:rights>
   </xsl:template>
   


   
   <!-- LEXICAL RESOURCES -->
   
   <!-- dc.subject & dc.type & dc.format & dc.language -->
   <xsl:template match="ms:resourceInfo/ms:resourceComponentType/ms:lexicalConceptualResourceInfo">

      <dc:subject>
         <xsl:text>'language resources', 'lexical conceptual resource', '</xsl:text>
         <xsl:value-of
            select="/ms:resourceInfo/ms:resourceComponentType/ms:lexicalConceptualResourceInfo/ms:lexicalConceptualResourceMediaType/ms:lexicalConceptualResourceTextInfo/ms:lingualityInfo/ms:lingualityType"/>
         <xsl:text> </xsl:text>
         <xsl:value-of
            select="/ms:resourceInfo/ms:resourceComponentType/ms:lexicalConceptualResourceInfo/ms:lexicalConceptualResourceType"/>
         <xsl:text>'</xsl:text>
      </dc:subject>
      
        
      <!-- Metashare lexicalConceptualResourceType -> OLAC Vocabulary lexicon (currently everything goes to olac lexicon and dcterms Dataset) -->
      <xsl:choose>
         <xsl:when test="./ms:lexicalConceptualResourceType = 'lexicon'">
            <dc:type xsi:type="olac:linguistic-type" olac:code="lexicon"/>
            <dc:type>
               <xsl:attribute name="xsi:type">
                  <xsl:text>dcterms:DCMIType</xsl:text>
               </xsl:attribute>   
               <xsl:text>Dataset</xsl:text>
            </dc:type>  
         </xsl:when>
         <xsl:when test="./ms:lexicalConceptualResourceType = 'lexicon/wordList'">
            <dc:type xsi:type="olac:linguistic-type" olac:code="lexicon"/>
            <dc:type>
               <xsl:attribute name="xsi:type">
                  <xsl:text>dcterms:DCMIType</xsl:text>
               </xsl:attribute>   
               <xsl:text>Dataset</xsl:text>
            </dc:type>  
         </xsl:when>
         <xsl:when test="./ms:lexicalConceptualResourceType = 'thesaurus'">
            <dc:type xsi:type="olac:linguistic-type" olac:code="lexicon"/>
            <dc:type>
               <xsl:attribute name="xsi:type">
                  <xsl:text>dcterms:DCMIType</xsl:text>
               </xsl:attribute>   
               <xsl:text>Dataset</xsl:text>
            </dc:type>  
         </xsl:when>
         <xsl:when test="./ms:lexicalConceptualResourceType = 'terminologicalResource'">
            <dc:type xsi:type="olac:linguistic-type" olac:code="lexicon"/>
            <dc:type>
               <xsl:attribute name="xsi:type">
                  <xsl:text>dcterms:DCMIType</xsl:text>
               </xsl:attribute>   
               <xsl:text>Dataset</xsl:text>
            </dc:type>  
         </xsl:when>
         <xsl:otherwise>
            <dc:type xsi:type="olac:linguistic-type" olac:code="lexicon"/>
            <dc:type>
               <xsl:attribute name="xsi:type">
                  <xsl:text>dcterms:DCMIType</xsl:text>
               </xsl:attribute>   
               <xsl:text>Dataset</xsl:text>
            </dc:type>  
         </xsl:otherwise>
      </xsl:choose>

     
      <xsl:if
         test="./ms:lexicalConceptualResourceMediaType/ms:lexicalConceptualResourceTextInfo/ms:textFormatInfo/ms:mimeType">
         <dc:format>

            <xsl:value-of
               select="./ms:lexicalConceptualResourceMediaType/ms:lexicalConceptualResourceTextInfo/ms:textFormatInfo/ms:mimeType"/>

         </dc:format>
      </xsl:if>
      <xsl:if
         test="./ms:lexicalConceptualResourceMediaType/ms:lexicalConceptualResourceTextInfo/ms:characterEncodingInfo/ms:characterEncoding">
         <dc:format>

            <xsl:value-of
               select="./ms:lexicalConceptualResourceMediaType/ms:lexicalConceptualResourceTextInfo/ms:characterEncodingInfo/ms:characterEncoding"/>

         </dc:format>
      </xsl:if>

      <xsl:for-each
         select="./ms:lexicalConceptualResourceMediaType/ms:lexicalConceptualResourceTextInfo/ms:languageInfo">
         <dc:language>
            <xsl:attribute name="xsi:type">
               <xsl:text>olac:language</xsl:text>
            </xsl:attribute>
            <xsl:attribute name="olac:code">
               <xsl:value-of select="./ms:languageId"/>
            </xsl:attribute>
         </dc:language>
      </xsl:for-each>   

   </xsl:template>

   <!-- CORPUS -->

   <xsl:template match="/ms:resourceInfo/ms:resourceComponentType/ms:corpusInfo">

      <dc:subject>
         <xsl:text>'language resources', '</xsl:text>
         <xsl:value-of
            select="/ms:resourceInfo/ms:resourceComponentType/ms:corpusInfo/ms:corpusMediaType/ms:corpusTextInfo/ms:lingualityInfo/ms:lingualityType"/>
         <xsl:text> corpus'</xsl:text>
      </dc:subject>
      
      <dc:type xsi:type="olac:linguistic-type" olac:code="primary_text"/>

      <xsl:choose>
         <xsl:when test="./ms:corpusMediaType/ms:corpusTextInfo/ms:mediaType = 'corpusAudioInfo'">
            <dc:type>
               <xsl:attribute name="xsi:type">
                  <xsl:text>dcterms:DCMIType</xsl:text>
               </xsl:attribute>   
               <xsl:text>Sound</xsl:text>
            </dc:type>
         </xsl:when>
         <xsl:when test="./ms:corpusMediaType/ms:corpusTextInfo/ms:mediaType = 'corpusTextInfo'">
            <dc:type>
               <xsl:attribute name="xsi:type">
                  <xsl:text>dcterms:DCMIType</xsl:text>
               </xsl:attribute>   
               <xsl:text>Text</xsl:text>
            </dc:type>
         </xsl:when>
         <xsl:when test="./ms:corpusMediaType/ms:corpusTextInfo/ms:mediaType = 'corpusImageInfo'">
            <dc:type>
               <xsl:attribute name="xsi:type">
                  <xsl:text>dcterms:DCMIType</xsl:text>
               </xsl:attribute>   
               <xsl:text>Image</xsl:text>
            </dc:type>
         </xsl:when>
      </xsl:choose>

      <xsl:if test="./ms:corpusMediaType/ms:corpusTextInfo/ms:textFormatInfo/ms:mimeType">
         <dc:format>

            <xsl:value-of
               select="./ms:corpusMediaType/ms:corpusTextInfo/ms:textFormatInfo/ms:mimeType"/>

         </dc:format>
      </xsl:if>
      <xsl:if
         test="./ms:corpusMediaType/ms:corpusTextInfo/ms:characterEncodingInfo/ms:characterEncoding">
         <dc:format>

            <xsl:value-of
               select="./ms:corpusMediaType/ms:corpusTextInfo/ms:characterEncodingInfo/ms:characterEncoding"/>

         </dc:format>
      </xsl:if>

      <xsl:for-each select="./ms:corpusMediaType/ms:corpusTextInfo/ms:languageInfo">
         <dc:language>
            <xsl:attribute name="xsi:type">
               <xsl:text>olac:language</xsl:text>
            </xsl:attribute>
            <xsl:attribute name="olac:code">
               <xsl:value-of select="./ms:languageId"/>
            </xsl:attribute>
         </dc:language>
      </xsl:for-each>

   </xsl:template>


   <!-- TOOLS -->

   <xsl:template match="/ms:resourceInfo/ms:resourceComponentType/ms:toolServiceInfo">

      <xsl:choose>
         <xsl:when test="./ms:toolServiceType = 'service'">
            <dc:type>
               <xsl:attribute name="xsi:type">
                  <xsl:text>dcterms:DCMIType</xsl:text>
               </xsl:attribute>   
                  <xsl:text>Service</xsl:text>
            </dc:type>
         </xsl:when>
         <xsl:otherwise>
            <dc:type>
               <xsl:attribute name="xsi:type">
                  <xsl:text>dcterms:DCMIType</xsl:text>
               </xsl:attribute>
               
                  <xsl:text>Software</xsl:text>
               
            </dc:type>
         </xsl:otherwise>
      </xsl:choose>

      <dc:subject>
         <xsl:text>'language resources', 'language </xsl:text>
         <xsl:value-of
            select="/ms:resourceInfo/ms:resourceComponentType/ms:toolServiceInfo/ms:toolServiceType"/>
         <xsl:text>', '</xsl:text>
         <xsl:value-of
            select="/ms:resourceInfo/ms:resourceComponentType/ms:toolServiceInfo/ms:toolServiceSubtype"/>
         <xsl:text>'</xsl:text>
      </dc:subject>

   </xsl:template>


 
   


</xsl:stylesheet>
