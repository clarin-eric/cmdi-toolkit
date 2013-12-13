<?xml version="1.0" encoding="UTF-8"?>
<!--
$Rev$
$LastChangedDate$
-->
<xsl:stylesheet xmlns="http://www.clarin.eu/cmd/"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:MPI="http://www.mpi.nl/"
    version="2.0"
    xpath-default-namespace="http://www.mpi.nl/IMDI/Schema/IMDI">
    
    <!-- Check if Handle System handle references an object hosted by MPI or not. -->
    <xsl:function 
        name="MPI:is_MPI_handle"
        as="xs:boolean">
        <xsl:param 
            name="handle" 
            as="xs:string"/>
        <xsl:sequence
            select="starts-with(normalize-space($handle), 'hdl:1839/')"/>
        <!--<xsl:value-of select="$return_value"/>-->
    </xsl:function>
    
    <!-- Produce URL to view IMDI file at IMDI_URL IMDI Browser based on MPI handle -->
    <xsl:function 
        name="MPI:URL_to_view_in_IMDI_Browser_by_handle"
        as="xs:string">
        <xsl:param 
            name="IMDI_URL" 
            as="xs:string"/>
        <xsl:sequence 
            select="concat($IMDI_browser_URL, 'ds/imdi_browser/?openhandle=', encode-for-uri($IMDI_URL))"/>  
        <!--<xsl:value-of select="$return_value"/>-->
    </xsl:function>
    
    <!-- Produce URL to view IMDI file at IMDI_URL IMDI Browser based on path (= URL) -->
    <xsl:function 
        name="MPI:URL_to_view_in_IMDI_Browser_by_path"
        as="xs:string">
        <xsl:param 
            name="IMDI_URL" 
            as="xs:string"/>
        <xsl:sequence 
            select="concat($IMDI_browser_URL, 'ds/imdi_browser/?openpath=', encode-for-uri($IMDI_URL))"/>  
        <!--<xsl:value-of select="$return_value"/>-->
    </xsl:function>
    
    <!-- This is a version of imdi2clarin.xsl that batch processes a whole directory structure of imdi files, call it from the command line like this:
    java -jar saxon8.jar -it main batch-imdi2clarin.xsl
    the last template in this file has to be modified to reflect the actual directory name. -->
    <xsl:output 
        method="xml" 
        indent="yes"/>

    <!-- A collection name can be specified for each record. This information is extrinsic to the IMDI file, so it is given as an external parameter. Omit this if you are unsure. -->
    <xsl:param 
        name="collection" 
        select="''"
        as="xs:string"/>

    <!-- If this optional parameter is defined, the behaviour of this stylesheet changes in the following ways: If no archive handle is
    available for MdSelfLink, the base URI is inserted there instead. All links (ResourceProxy elements) that contain relative
    paths are resolved into absolute URIs in the context of the base URI. Omit this if you are unsure. -->
    <xsl:param 
        name="uri-base" 
        select="''"
        as="xs:string"/>
    
    <!-- An URL (composed of scheme and host URL components) pointing to the IMDI browser -->
    <xsl:param 
        name="IMDI_browser_URL" 
        select="'http://corpus1.mpi.nl/'" 
        as="xs:string"/>

    <!-- A URL pointing to the imdi-to-cmdi translation service, with
    'IMDI' to be replaced by the URL or handle of the IMDI file. -->
    <xsl:param name="translation_service_url"
	       select="'http://corpus1.mpi.nl/ds/TranslationService/translate?in=IMDI&amp;outFormat=cmdi'"
	       as="xs:string"/>

    <!-- A prefix for the MdCollectionDisplayName with a meaning similar to the old 'Data provider' facet in the Virtual Language Observatory. -->
    <xsl:param 
        name="collection_display_name_prefix" 
        select="'TLA'" 
        as="xs:string"/> 

    <!-- definition of the SRU-searchable collections at TLA (for use later on) -->
    <xsl:variable 
        name="SruSearchable" 
        select="('childes','ESF corpus','IFA corpus','MPI CGN','talkbank')"
        as='xs:string+'/>
    
    <xsl:template 
        name="metatranscriptDelegate">
        <xsl:param 
            name="profile" 
            as="xs:string"
            select="''"/>
        <xsl:param 
            name="MdSelfLink" 
            as="xs:string"
            select="''"/>
        
        <Header>
            <MdCreator><xsl:text>imdi2clarin.xsl</xsl:text></MdCreator>
            <MdCreationDate>
                <xsl:value-of 
                    select="format-date(current-date(), '[Y]-[M01]-[D01]')"/>
            </MdCreationDate>
            <MdSelfLink>
                <xsl:value-of 
                    select="$MdSelfLink"/>            
            </MdSelfLink>
            <MdProfile>
                <xsl:value-of 
                    select="$profile"/>
            </MdProfile>
            <xsl:if 
                test="not(normalize-space($collection)='')">
                <MdCollectionDisplayName>
                    <xsl:choose>
                        <xsl:when 
                            test="not(normalize-space($collection_display_name_prefix)='')">
                            <xsl:value-of 
                                select="$collection_display_name_prefix"/><xsl:text>: </xsl:text><xsl:value-of 
                                                                                                     select="$collection"/>        
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:value-of 
                                select="$collection"/> 
                        </xsl:otherwise>
                    </xsl:choose>
                </MdCollectionDisplayName>
            </xsl:if>
        </Header>
        <Resources>
            <ResourceProxyList>
	      <!-- A landing page can only be created when either 1)
	      the file has an MPI handle or 2) $uri-base is
	      defined. Note especially that files are not required to
	      have a handle at all. That is not an error condition;
	      simply skip landing page creation. -->
	      <xsl:if test="(@ArchiveHandle and MPI:is_MPI_handle(@ArchiveHandle)) or not(normalize-space($uri-base)='')">
                <ResourceProxy id="{generate-id()}">
                  <ResourceType><xsl:text>LandingPage</xsl:text></ResourceType>                        
                  <xsl:choose>
                    <!-- Does ArchiveHandle attribute *exist* and does
                         it have an MPI handle prefix? Then generate a
                         LandingPage resource to the original IMDI -->
                    <xsl:when test="@ArchiveHandle and MPI:is_MPI_handle(@ArchiveHandle)">
                      <xsl:choose>
                        <xsl:when test="ends-with($MdSelfLink,'@format=cmdi')">
                          <ResourceRef><xsl:value-of 
                                          select="concat(substring-before($MdSelfLink,'@format=cmdi'),'@view')"/></ResourceRef>
                        </xsl:when>
                        <xsl:otherwise>
                          <ResourceRef><xsl:value-of select="concat($MdSelfLink,'@view')"/></ResourceRef>
                        </xsl:otherwise>
                      </xsl:choose>                                
                    </xsl:when>
		    <!-- Either there is no handle or it is not an MPI
			 one; however $uri-base is available. Use it
			 as LandingPage, because the IMDI Browser
			 cannot show external resources.-->
                    <xsl:otherwise>
                      <ResourceRef><xsl:value-of 
                                      select="MPI:URL_to_view_in_IMDI_Browser_by_path($uri-base)"/></ResourceRef> 
                    </xsl:otherwise>
                  </xsl:choose>      
                </ResourceProxy>
              </xsl:if>

                <xsl:apply-templates 
                    select="//Resources" 
                    mode="linking"/>
                <xsl:apply-templates 
                    select="//Description[not(normalize-space(./@ArchiveHandle)='') or not(normalize-space(./@Link)='')]" 
                    mode="linking"/>
                <xsl:apply-templates 
                    select="//Corpus" 
                    mode="linking"/>
                <!-- If this collection name is indicated to be SRU-searchable, add a link to the TLA SRU endpoint -->
                <xsl:if 
                    test="not(normalize-space($collection)='') and (some $searchable_collection in $SruSearchable satisfies $collection = $searchable_collection)">
                    <ResourceProxy id="sru">
                        <ResourceType><xsl:text>SearchService</xsl:text></ResourceType>
                        <ResourceRef><xsl:text>http://cqlservlet.mpi.nl/</xsl:text></ResourceRef>
                    </ResourceProxy>
                </xsl:if>
            </ResourceProxyList>
            <JournalFileProxyList> </JournalFileProxyList>
            <ResourceRelationList> </ResourceRelationList>
        </Resources>
        <Components>
            <xsl:apply-templates 
                select="Session"/>
            <xsl:apply-templates 
                select="Corpus"/>
        </Components>
    </xsl:template>

    <xsl:template 
        match="METATRANSCRIPT" 
        name="METATRANSCRIPT_rec">
        <xsl:param 
            name="MdSelfLink"
            select="''"
            as="xs:string"/>
        <xsl:choose>
            <xsl:when 
                test="not(normalize-space($MdSelfLink))">
                <xsl:choose>
                    <!-- MPI handle prefix? Use handle + @format=cmdi suffix -->
                    <xsl:when 
                        test="@ArchiveHandle and MPI:is_MPI_handle(@ArchiveHandle)">
                        <xsl:call-template 
                            name="METATRANSCRIPT_rec">
                            <xsl:with-param 
                                name="MdSelfLink" 
                                as="xs:string"
                                select="concat(@ArchiveHandle, '@format=cmdi')"/>
                        </xsl:call-template>
                    </xsl:when>
                    <!-- No handle but $uri-base was specified? Then use $uri-base. -->
                    <xsl:when 
                        test="not($uri-base='') and normalize-space(@ArchiveHandle)=''">
                        <xsl:call-template 
                            name="METATRANSCRIPT_rec">
                            <xsl:with-param 
                                name="MdSelfLink" 
                                as="xs:string"
                                select="$uri-base"/>
                        </xsl:call-template>
                    </xsl:when>
                    <!-- Other handle prefix? Use handle (e.g. Lund) -->
                    <xsl:otherwise>
                        <xsl:call-template 
                            name="METATRANSCRIPT_rec">
                            <xsl:with-param 
                                name="MdSelfLink" 
                                as="xs:string"
                                select="@ArchiveHandle"/>
                        </xsl:call-template>
                    </xsl:otherwise> 
                </xsl:choose>
            </xsl:when>
            <xsl:otherwise>
               <xsl:choose>
                   <xsl:when 
                       test=".[@Type='SESSION'] or .[@Type='SESSION.Profile']">
                       <CMD 
                           CMDVersion="1.1" 
                           xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
                           xsi:schemaLocation="http://www.clarin.eu/cmd/ http://catalog.clarin.eu/ds/ComponentRegistry/rest/registry/profiles/clarin.eu:cr1:p_1271859438204/xsd">
                           <xsl:call-template 
                               name="metatranscriptDelegate">
                               <xsl:with-param 
                                   name="profile"
                                   as="xs:string"
                                   select="'clarin.eu:cr1:p_1271859438204'"/>
                               <xsl:with-param 
                                   name="MdSelfLink"
                                   as="xs:string"
                                   select="$MdSelfLink"/>
                           </xsl:call-template>
                       </CMD>
                   </xsl:when>
                   <xsl:when test=".[@Type='CORPUS'] or .[@Type='CORPUS.Profile']">
                       <CMD 
                           CMDVersion="1.1" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
                           xsi:schemaLocation="http://www.clarin.eu/cmd/ http://catalog.clarin.eu/ds/ComponentRegistry/rest/registry/profiles/clarin.eu:cr1:p_1274880881885/xsd">
                           <xsl:call-template 
                               name="metatranscriptDelegate">
                               <xsl:with-param 
                                   name="profile"
                                   select="'clarin.eu:cr1:p_1274880881885'"/>
                               <xsl:with-param 
                                   name="MdSelfLink"
                                   as="xs:string"
                                   select="$MdSelfLink"/>
                           </xsl:call-template>
                       </CMD>
                   </xsl:when>
                   <xsl:otherwise>
                       <!-- Currently we are only processing 'SESSION' and 'CORPUS' types. The error displayed can be used to filter out erroneous files after processing -->
                       <xsl:message 
                           terminate="yes">
                           <xsl:text>ERROR: Invalid METATRANSCRIPT type: </xsl:text><xsl:value-of select="name()"/>
                       </xsl:message>
                    </xsl:otherwise>
               </xsl:choose>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <xsl:template 
        match="Corpus">
        <imdi-corpus>
            <Corpus>
                <xsl:apply-templates select="child::Name"/>
                <xsl:apply-templates select="child::Title"/>
                <xsl:if test="exists(child::Description)">
                    <descriptions>
                        <xsl:variable name="reflist">
                            <xsl:for-each select="Description">
                                <xsl:if test="not(normalize-space(@ArchiveHandle)='') or not(normalize-space(@Link)='')">
                                    <xsl:value-of select="generate-id()"/>
                                    <xsl:text> </xsl:text>
                                </xsl:if>
                            </xsl:for-each> 
                        </xsl:variable>
                        
                        <xsl:attribute name="ref" select="normalize-space($reflist)"></xsl:attribute>
                        
                        <xsl:for-each select="Description">
                        <Description>
                            <xsl:attribute name="LanguageId" select="@LanguageId"/>
                            <xsl:value-of select="."/>
                        </Description>
                        </xsl:for-each>
                        
                    </descriptions>
                </xsl:if>
                <xsl:if test="exists(child::CorpusLink)">
                    <xsl:for-each select="CorpusLink">
                        <CorpusLink>
                            <CorpusLinkContent>
                                <!--<xsl:attribute name="ArchiveHandle" select="@ArchiveHandle"/>-->
                                <xsl:attribute name="Name" select="@Name"/>
                                <xsl:value-of select="."/>
                            </CorpusLinkContent>
                        </CorpusLink>
                    </xsl:for-each>
                </xsl:if>
            </Corpus>
        </imdi-corpus>
    </xsl:template>

    <xsl:template 
        match="Corpus" mode="linking">
        <xsl:for-each select="CorpusLink">
            <ResourceProxy id="{generate-id()}">
                <ResourceType><xsl:text>Metadata</xsl:text></ResourceType>
                <ResourceRef>
                    <xsl:choose>
                        <xsl:when test="not(normalize-space(./@ArchiveHandle)='')">
			  <xsl:choose>
			    <xsl:when test="MPI:is_MPI_handle(@ArchiveHandle) and not(contains(./@ArchiveHandle, '@'))">
			      <xsl:value-of select="./@ArchiveHandle"/><xsl:text>@format=cmdi</xsl:text>
			    </xsl:when>
			    <xsl:otherwise>
			      <xsl:value-of select="./@ArchiveHandle"/>
			    </xsl:otherwise>
			  </xsl:choose>
                        </xsl:when>
                        <xsl:when test="starts-with(., 'hdl:')">
                            <xsl:value-of select="."/>
                        </xsl:when>
                        <xsl:when test="$uri-base=''"><xsl:value-of select="replace($translation_service_url, 'IMDI', .)"/></xsl:when>
                        <xsl:otherwise>
                            <xsl:value-of
                                select="replace($translation_service_url,'IMDI',resolve-uri(normalize-space(.), $uri-base))"/>
                        </xsl:otherwise>
                    </xsl:choose>
                </ResourceRef>
            </ResourceProxy>
        </xsl:for-each>
    </xsl:template>

    <!-- Create ResourceProxy for MediaFile and WrittenResource -->
    <xsl:template 
        match="Resources" 
        mode="linking">
        <xsl:for-each select="MediaFile">
            <xsl:call-template 
                name="CreateResourceProxyTypeResource"/>        
        </xsl:for-each>
        <xsl:for-each 
            select="WrittenResource">
            <xsl:call-template 
                name="CreateResourceProxyTypeResource"/>
        </xsl:for-each>
    </xsl:template>
    
    <!-- Create ResourceProxy for Info files -->
    <xsl:template 
        match="//Description[@ArchiveHandle or @Link]" 
        mode="linking">
        <xsl:call-template 
            name="CreateResourceProxyTypeResource"/>
    </xsl:template> 
    
    <!-- To be called during the creation of the ResourceProxyList (in linking mode) -->
    <xsl:template 
        name="CreateResourceProxyTypeResource">
        <ResourceProxy id="{generate-id()}">
            <ResourceType>
                <xsl:if test="exists(Format) and not(empty(Format))">
                    <xsl:attribute name="mimetype">
                        <xsl:value-of select="./Format"/>
                    </xsl:attribute>
                </xsl:if>
                <xsl:text>Resource</xsl:text>
            </ResourceType>
            <ResourceRef>
                <xsl:choose>
                    <xsl:when test="not(normalize-space(ResourceLink/@ArchiveHandle)='')">
                        <xsl:value-of select="ResourceLink/@ArchiveHandle"/>
                    </xsl:when>
                    <xsl:when test="not($uri-base='')">
                        <xsl:value-of
                            select="resolve-uri(normalize-space(ResourceLink/.), $uri-base)"/>
                    </xsl:when>
                    <!-- for info files the @ArchiveHandle or @Link is part of the Description element - preference for ArchiveHandle -->
                    <xsl:when test="not(normalize-space(@ArchiveHandle)='')">
                        <xsl:value-of select="@ArchiveHandle"/>
                    </xsl:when>
                    <xsl:when test="not(normalize-space(@Link)='')">
                        <xsl:value-of select="@Link"/>
                    </xsl:when>
                </xsl:choose>
            </ResourceRef>
        </ResourceProxy>
    </xsl:template>
    
    <xsl:template 
        match="Session">
        <Session>
            <xsl:apply-templates select="child::Name"/>
            <xsl:apply-templates select="child::Title"/>
            <xsl:apply-templates select="child::Date"/>
            <xsl:if test="exists(child::Description)">
                <descriptions>
                    <xsl:variable name="reflist">
                        <xsl:for-each select="Description">
                            <xsl:if test="not(normalize-space(@ArchiveHandle)='') or not(normalize-space(@Link)='')">
                                <xsl:value-of select="generate-id()"/>
                                <xsl:text> </xsl:text>
                            </xsl:if>
                        </xsl:for-each> 
                    </xsl:variable>
                    
                    <xsl:if test="not(normalize-space($reflist)='')">
                        <xsl:attribute name="ref" select="normalize-space($reflist)"></xsl:attribute>
                    </xsl:if>

                    <xsl:for-each select="Description">
                        <Description>
                            <xsl:attribute name="LanguageId" select="@LanguageId"/>
                            <xsl:value-of select="."/>
                        </Description>
                    </xsl:for-each>
                </descriptions>
            </xsl:if>
            <xsl:apply-templates select="child::MDGroup"/>
            <xsl:apply-templates select="child::Resources" mode="regular"/>
            <xsl:apply-templates select="child::References"/>
        </Session>
    </xsl:template>

    <xsl:template 
        match="child::Name">
        <Name>
            <xsl:value-of select="."/>
        </Name>
    </xsl:template>

    <xsl:template 
        match="child::Title">
        <Title>
            <xsl:value-of select="."/>
        </Title>
    </xsl:template>

    <xsl:template 
        match="child::Date">
        <Date>
            <xsl:value-of select="."/>
        </Date>
    </xsl:template>

    <xsl:template 
        match="child::MDGroup">
        <MDGroup>
            <xsl:apply-templates 
                select="child::Location"/>
            <xsl:apply-templates 
                select="child::Project"/>
            <xsl:apply-templates 
                select="child::Keys"/>
            <xsl:apply-templates 
                select="child::Content"/>
            <xsl:apply-templates 
                select="child::Actors"/>
        </MDGroup>
    </xsl:template>

    <xsl:template 
        match="Location">
        <Location>
            <Continent>
                <xsl:value-of 
                    select="child::Continent"/>
            </Continent>
            <Country>
                <xsl:value-of 
                    select="child::Country"/>
            </Country>
            <xsl:if 
                test="exists(child::Region)">
                <Region>
                    <xsl:value-of 
                        select="child::Region"/>
                </Region>
            </xsl:if>
            <xsl:if 
                test="exists(child::Address)">
                <Address>
                    <xsl:value-of 
                        select="child::Address"/>
                </Address>
            </xsl:if>
        </Location>
    </xsl:template>

    <xsl:template 
        match="Project">
        <Project>
            <Name>
                <xsl:value-of select="child::Name"/>
            </Name>
            <Title>
                <xsl:value-of select="child::Title"/>
            </Title>
            <Id>
                <xsl:value-of select="child::Id"/>
            </Id>
            <xsl:apply-templates select="Contact"/>
            <xsl:if test="exists(child::Description)">
                <descriptions>
                    <xsl:for-each select="Description">
                        <Description>
                            <xsl:attribute 
                                name="LanguageId" 
                                select="@LanguageId"/>
                            <xsl:value-of select="."/>
                        </Description>
                    </xsl:for-each>
                </descriptions>
            </xsl:if>
        </Project>
    </xsl:template>

    <xsl:template 
        match="Contact">
        <Contact>
            <Name>
                <xsl:value-of select="child::Name"/>
            </Name>
            <Address>
                <xsl:value-of select="child::Address"/>
            </Address>
            <Email>
                <xsl:value-of select="child::Email"/>
            </Email>
            <Organisation>
                <xsl:value-of select="child::Organisation"/>
            </Organisation>
        </Contact>
    </xsl:template>

    <xsl:template 
        match="Keys">
        <Keys>
            <xsl:for-each select="Key">
                <Key>
                    <xsl:attribute name="Name">
                        <xsl:value-of select="@Name"/>
                    </xsl:attribute>
                    <xsl:value-of select="."/>
                </Key>
            </xsl:for-each>
        </Keys>
    </xsl:template>

    <xsl:template 
        match="Content">
        <Content>
            <Genre>
                <xsl:value-of select="child::Genre"/>
            </Genre>
            <xsl:if test="exists(child::SubGenre)">
                <SubGenre>
                    <xsl:value-of select="child::SubGenre"/>
                </SubGenre>
            </xsl:if>
            <xsl:if test="exists(child::Task)">
                <Task>
                    <xsl:value-of select="child::Task"/>
                </Task>
            </xsl:if>
            <xsl:if test="exists(child::Modalities)">
                <Modalities>
                    <xsl:value-of select="child::Modalities"/>
                </Modalities>
            </xsl:if>
            <xsl:if test="exists(child::Subject)">
                <Subject>
                    <xsl:value-of select="child::Subject"/>
                </Subject>
            </xsl:if>
            <xsl:apply-templates select="child::CommunicationContext"/>
            <xsl:apply-templates select="child::Languages" mode="content"/>
            <xsl:apply-templates select="child::Keys"/>
            <xsl:if test="exists(child::Description)">
                <descriptions>
                    <xsl:for-each select="Description">
                        <Description>
                            <xsl:attribute name="LanguageId" select="@LanguageId"/>
                            <xsl:value-of select="."/>
                        </Description>
                    </xsl:for-each>
                </descriptions>
            </xsl:if>
        </Content>

    </xsl:template>

    <xsl:template 
        match="CommunicationContext">
        <CommunicationContext>
            <xsl:if test="exists(child::Interactivity)">
                <Interactivity>
                    <xsl:value-of select="child::Interactivity"/>
                </Interactivity>
            </xsl:if>
            <xsl:if test="exists(child::PlanningType)">
                <PlanningType>
                    <xsl:value-of select="child::PlanningType"/>
                </PlanningType>
            </xsl:if>
            <xsl:if test="exists(child::Involvement)">
                <Involvement>
                    <xsl:value-of select="child::Involvement"/>
                </Involvement>
            </xsl:if>
            <xsl:if test="exists(child::SocialContext)">
                <SocialContext>
                    <xsl:value-of select="child::SocialContext"/>
                </SocialContext>
            </xsl:if>
            <xsl:if test="exists(child::EventStructure)">
                <EventStructure>
                    <xsl:value-of select="child::EventStructure"/>
                </EventStructure>
            </xsl:if>
            <xsl:if test="exists(child::Channel)">
                <Channel>
                    <xsl:value-of select="child::Channel"/>
                </Channel>
            </xsl:if>
        </CommunicationContext>
    </xsl:template>

    <xsl:template 
        match="Languages" 
        mode="content">
        <Content_Languages>
            <xsl:if test="exists(child::Description)">
                <descriptions>
                    <xsl:for-each 
                        select="Description">
                        <Description>
                            <xsl:attribute 
                                name="LanguageId" 
                                select="@LanguageId"/>
                            <xsl:value-of 
                                select="."/>
                        </Description>
                    </xsl:for-each>
                </descriptions>
            </xsl:if>
            <xsl:for-each 
                select="Language">
                <Content_Language>
                    <Id>
                        <xsl:value-of 
                            select=" ./Id"/>
                    </Id>
                    <Name>
                        <xsl:value-of 
                            select=" ./Name"/>
                    </Name>
                    <xsl:if 
                        test="exists(child::Dominant)">
                        <Dominant>
                            <xsl:value-of 
                                select=" ./Dominant"/>
                        </Dominant>
                    </xsl:if>
                    <xsl:if 
                        test="exists(child::SourceLanguage)">
                        <SourceLanguage>
                            <xsl:value-of 
                                select=" ./SourceLanguage"/>
                        </SourceLanguage>
                    </xsl:if>
                    <xsl:if 
                        test="exists(child::TargetLanguage)">
                        <TargetLanguage>
                            <xsl:value-of 
                                select=" ./TargetLanguage"/>
                        </TargetLanguage>
                    </xsl:if>
                    <xsl:if 
                        test="exists(child::Description)">
                        <descriptions>
                            <xsl:for-each 
                                select="Description">
                                <Description>
                                    <xsl:attribute 
                                        name="LanguageId" 
                                        select="@LanguageId"/>
                                    <xsl:value-of select="."/>
                                </Description>
                            </xsl:for-each>
                        </descriptions>
                    </xsl:if>
                </Content_Language>
            </xsl:for-each>
        </Content_Languages>
    </xsl:template>

    <xsl:template 
        match="Actors">
        <Actors>
            <xsl:if test="exists(child::Description)">
                <descriptions>
                    <xsl:for-each select="Description">
                        <Description>
                            <xsl:attribute name="LanguageId" select="@LanguageId"/>
                            <xsl:value-of select="."/>
                        </Description>
                    </xsl:for-each>
                </descriptions>
            </xsl:if>
            <xsl:for-each select="Actor">
                <Actor>
                    <Role>
                        <xsl:value-of select=" ./Role"/>
                    </Role>
                    <Name>
                        <xsl:value-of select=" ./Name"/>
                    </Name>
                    <FullName>
                        <xsl:value-of select=" ./FullName"/>
                    </FullName>
                    <Code>
                        <xsl:value-of select=" ./Code"/>
                    </Code>
                    <FamilySocialRole>
                        <xsl:value-of select=" ./FamilySocialRole"/>
                    </FamilySocialRole>
                    <EthnicGroup>
                        <xsl:value-of select=" ./EthnicGroup"/>
                    </EthnicGroup>
                    <Age>
                        <xsl:value-of select=" ./Age"/>
                    </Age>
                    <BirthDate>
                        <xsl:value-of select=" ./BirthDate"/>
                    </BirthDate>
                    <Sex>
                        <xsl:value-of select=" ./Sex"/>
                    </Sex>
                    <Education>
                        <xsl:value-of select=" ./Education"/>
                    </Education>
                    <Anonymized>
                        <xsl:value-of select=" ./Anonymized"/>
                    </Anonymized>
                    <xsl:apply-templates select="Contact"/>
                    <xsl:apply-templates select="child::Keys"/>
                    <xsl:if test="exists(child::Description)">
                        <descriptions>
                            <xsl:for-each select="Description">
                                <Description>
                                    <xsl:attribute name="LanguageId" select="@LanguageId"/>
                                    <xsl:value-of select="."/>
                                </Description>
                            </xsl:for-each>
                        </descriptions>
                    </xsl:if>
                    <xsl:apply-templates select="child::Languages" mode="actor"/>
                </Actor>
            </xsl:for-each>
        </Actors>
    </xsl:template>

    <xsl:template 
        match="Languages" 
        mode="actor">
        <Actor_Languages>
            <xsl:if test="exists(child::Description)">
                <descriptions>
                    <xsl:for-each select="Description">
                        <Description>
                            <xsl:attribute name="LanguageId" select="@LanguageId"/>
                            <xsl:value-of select="."/>
                        </Description>
                    </xsl:for-each>
                </descriptions>
            </xsl:if>
            <xsl:for-each select="Language">
                <Actor_Language>
                    <Id>
                        <xsl:value-of select=" ./Id"/>
                    </Id>
                    <Name>
                        <xsl:value-of select=" ./Name"/>
                    </Name>
                    <xsl:if test="exists(child::MotherTongue)">
                        <MotherTongue>
                            <xsl:value-of select=" ./MotherTongue"/>
                        </MotherTongue>
                    </xsl:if>
                    <xsl:if test="exists(child::PrimaryLanguage)">
                        <PrimaryLanguage>
                            <xsl:value-of select=" ./PrimaryLanguage"/>
                        </PrimaryLanguage>
                    </xsl:if>
                    <xsl:if test="exists(child::Description)">
                        <descriptions>
                            <xsl:for-each select="Description">
                                <Description>
                                    <xsl:attribute name="LanguageId" select="@LanguageId"/>
                                    <xsl:value-of select="."/>
                                </Description>
                            </xsl:for-each>
                        </descriptions>
                    </xsl:if>
                </Actor_Language>
            </xsl:for-each>
        </Actor_Languages>
    </xsl:template>

    <xsl:template 
        match="child::Resources" 
        mode="regular">
        <Resources>
            <xsl:apply-templates select="MediaFile"/>
            <xsl:apply-templates select="WrittenResource"/>
            <xsl:apply-templates select="Source"/>
            <xsl:apply-templates select="Anonyms"/>
        </Resources>
    </xsl:template>

    <xsl:template 
        match="MediaFile">
        <MediaFile 
            ref="{generate-id()}">
            <ResourceLink>
                <xsl:value-of 
                    select=" ./ResourceLink"/>
            </ResourceLink>
            <Type>
                <xsl:value-of 
                    select=" ./Type"/>
            </Type>
            <Format>
                <xsl:value-of 
                    select=" ./Format"/>
            </Format>
            <Size>
                <xsl:value-of 
                    select=" ./Size"/>
            </Size>
            <Quality>
                <xsl:value-of 
                    select=" ./Quality"/>
            </Quality>
            <RecordingConditions>
                <xsl:value-of 
                    select=" ./RecordingConditions"/>
            </RecordingConditions>
            <TimePosition>
                <Start>
                    <xsl:apply-templates 
                        select="TimePosition/Start"/>
                </Start>
                <xsl:if test="exists(descendant::End)">
                    <End>
                        <xsl:apply-templates 
                            select="TimePosition/End"/>
                    </End>
                </xsl:if>
            </TimePosition>
            <xsl:apply-templates select="Access"/>
            <xsl:if test="exists(child::Description)">
                <descriptions>
                    <xsl:for-each select="Description">
                        <Description>
                            <xsl:attribute 
                                name="LanguageId" 
                                select="@LanguageId"/>
                            <xsl:value-of select="."/>
                        </Description>
                    </xsl:for-each>
                </descriptions>
            </xsl:if>
            <xsl:apply-templates select="child::Keys"/>
        </MediaFile>
    </xsl:template>

    <xsl:template 
        match="Access">
        <Access>
            <Availability>
                <xsl:value-of select=" ./Availability"/>
            </Availability>
            <Date>
                <xsl:value-of select=" ./Date"/>
            </Date>
            <Owner>
                <xsl:value-of select=" ./Owner"/>
            </Owner>
            <Publisher>
                <xsl:value-of select=" ./Publisher"/>
            </Publisher>
            <xsl:apply-templates select="Contact"/>
            <xsl:if test="exists(child::Description)">
                <descriptions>
                    <xsl:for-each select="Description">
                        <Description>
                            <xsl:attribute name="LanguageId" select="@LanguageId"/>
                            <xsl:value-of select="."/>
                        </Description>
                    </xsl:for-each>
                </descriptions>
            </xsl:if>
        </Access>
    </xsl:template>

    <xsl:template 
        match="WrittenResource">
        <WrittenResource ref="{generate-id()}">
            <ResourceLink>
                <xsl:value-of select=" ./ResourceLink"/>
            </ResourceLink>
            <MediaResourceLink>
                <xsl:value-of select=" ./MediaResourceLink"/>
            </MediaResourceLink>
            <Date>
                <xsl:value-of select=" ./Date"/>
            </Date>
            <Type>
                <xsl:value-of select=" ./Type"/>
            </Type>
            <SubType>
                <xsl:value-of select=" ./SubType"/>
            </SubType>
            <Format>
                <xsl:value-of select=" ./Format"/>
            </Format>
            <Size>
                <xsl:value-of select=" ./Size"/>
            </Size>
            <Derivation>
                <xsl:value-of select=" ./Derivation"/>
            </Derivation>
            <CharacterEncoding>
                <xsl:value-of select=" ./CharacterEncoding"/>
            </CharacterEncoding>
            <ContentEncoding>
                <xsl:value-of select=" ./ContentEncoding"/>
            </ContentEncoding>
            <LanguageId>
                <xsl:value-of select=" ./LanguageId"/>
            </LanguageId>
            <Anonymized>
                <xsl:value-of select=" ./Anonymized"/>
            </Anonymized>
            <xsl:apply-templates select="Validation"/>
            <xsl:apply-templates select="Access"/>
            <xsl:if test="exists(child::Description)">
                <descriptions>
                    <xsl:for-each select="Description">
                        <Description>
                            <xsl:attribute 
                                name="LanguageId" 
                                select="@LanguageId"/>
                            <xsl:value-of select="."/>
                        </Description>
                    </xsl:for-each>
                </descriptions>
            </xsl:if>
            <xsl:apply-templates select="Keys"/>
        </WrittenResource>
    </xsl:template>

    <xsl:template 
        match="Validation">
        <Validation>
            <Type>
                <xsl:value-of select=" ./Type"/>
            </Type>
            <Methodology>
                <xsl:value-of select=" ./Methodology"/>
            </Methodology>
            <Level>
                <xsl:value-of select=" ./Level"/>
            </Level>
            <xsl:if test="exists(child::Description)">
                <descriptions>
                    <xsl:for-each select="Description">
                        <Description>
                            <xsl:attribute name="LanguageId" select="@LanguageId"/>
                            <xsl:value-of select="."/>
                        </Description>
                    </xsl:for-each>
                </descriptions>
            </xsl:if>
        </Validation>
    </xsl:template>

    <xsl:template 
        match="Source">
        <Source>
            <Id>
                <xsl:value-of select=" ./Id"/>
            </Id>
            <Format>
                <xsl:value-of select=" ./Format"/>
            </Format>
            <Quality>
                <xsl:value-of select=" ./Quality"/>
            </Quality>
            <xsl:if test="exists(child::CounterPosition)">
                <CounterPosition>
                    <Start>
                        <xsl:apply-templates select="CounterPosition/Start"/>
                    </Start>
                    <xsl:if test="exists(descendant::End)">
                        <End>
                            <xsl:apply-templates select="CounterPosition/End"/>
                        </End>
                    </xsl:if>
                </CounterPosition>
            </xsl:if>
            <xsl:if test="exists(child::TimePosition)">
                <TimePosition>
                    <Start>
                        <xsl:apply-templates select="TimePosition/Start"/>
                    </Start>
                    <xsl:if test="exists(descendant::End)">
                        <End>
                            <xsl:apply-templates select="TimePosition/End"/>
                        </End>
                    </xsl:if>
                </TimePosition>
            </xsl:if>
            <xsl:apply-templates select="Access"/>
            <xsl:if test="exists(child::Description)">
                <descriptions>
                    <xsl:for-each select="Description">
                        <Description>
                            <xsl:attribute name="LanguageId" select="@LanguageId"/>
                            <xsl:value-of select="."/>
                        </Description>
                    </xsl:for-each>
                </descriptions>
            </xsl:if>
            <xsl:apply-templates select="child::Keys"/>
        </Source>
    </xsl:template>

    <xsl:template 
        match="Anonyms">
        <Anonyms>
            <ResourceLink>
                <xsl:value-of select=" ./ResourceLink"/>
            </ResourceLink>
            <xsl:apply-templates select="Access"/>
        </Anonyms>
    </xsl:template>

    <xsl:template 
        match="child::References">
        <References>
            <xsl:if test="exists(child::Description)">
                <descriptions>
                    <xsl:for-each select="Description">
                        <Description>
                            <xsl:attribute name="LanguageId" select="@LanguageId"/>
                            <xsl:value-of select="."/>
                        </Description>
                    </xsl:for-each>
                </descriptions>
            </xsl:if>
        </References>
    </xsl:template>

    <xsl:template 
        name="main">
        <xsl:for-each
            select="collection('file:///home/paucas/corpus_copy/corpus_copy/data/corpora?select=*.imdi;recurse=yes;on-error=ignore')">
            <xsl:result-document href="{document-uri(.)}.cmdi">
                <xsl:apply-templates select="."/>
            </xsl:result-document>
        </xsl:for-each>
    </xsl:template>

</xsl:stylesheet>
