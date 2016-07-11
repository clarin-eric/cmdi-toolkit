<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="2.0" xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:cmd="http://www.clarin.eu/cmd/1" xmlns:cue="http://www.clarin.eu/cmdi/cues/1">

    <xsl:param name="cmd-toolkit" select="'https://infra.clarin.eu/CMDI/1.x'"/>
    <xsl:param name="cmd-envelop" select="concat($cmd-toolkit,'/xsd/cmd-envelop.xsd')"/>

    <xsl:variable name="CMDVersion" select="'1.2'"/>
    
    <xsl:variable name="ns-uri" select="concat('http://www.clarin.eu/cmd/1/profiles/',/ComponentSpec/Header/ID)"/>
    
    <xsl:strip-space elements="*"/>

    <xsl:output method="xml" version="1.0" encoding="UTF-8" indent="no"/>

    <!-- resolve includes -->
    <xsl:template match="@*|node()" mode="include">
        <xsl:copy>
            <xsl:apply-templates select="@*|node()" mode="include"/>
        </xsl:copy>
    </xsl:template>

    <xsl:template match="Component[@filename]" mode="include">
        <!-- some of the outer CMD_Component attributes can overwrite the inner Component attributes -->
        <xsl:variable name="outer-attr" select="@CardinalityMin|@CardinalityMax"/>
        <xsl:for-each select="document(@filename)/ComponentSpec/Component">
            <xsl:variable name="inner-attr" select="@*"/>
            <xsl:copy>
                <xsl:apply-templates select="$outer-attr" mode="include"/>
                <xsl:apply-templates select="$inner-attr[not(node-name(.) = $outer-attr/node-name(.))]" mode="include"/>
                <xsl:apply-templates select="node()" mode="include"/>
            </xsl:copy>
        </xsl:for-each>
    </xsl:template>

    <!-- main -->
    <xsl:template match="/">
        <!-- Resolve all includes -->
        <xsl:variable name="tree">
            <xsl:apply-templates mode="include"/>
        </xsl:variable>
        <!-- Process the complete tree -->
        <xsl:apply-templates select="$tree/*"/>
    </xsl:template>

    <!-- generate XSD -->
    <xsl:template match="/ComponentSpec">

        <xs:schema xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:cmd="http://www.clarin.eu/cmd/1" targetNamespace="{$ns-uri}" elementFormDefault="qualified">
            
            <xsl:namespace name="cmdp" select="$ns-uri"/>

            <!-- put the header information from the component specification in the schema as appinfo -->
            <xs:annotation>
                <xs:appinfo xmlns:ann="http://www.clarin.eu">
                    <xsl:apply-templates select="Header" mode="Header"/>
                </xs:appinfo>
            </xs:annotation>

            <!-- import xml.xsd for the use of the xml:lang attribute -->
            <xs:import namespace="http://www.w3.org/XML/1998/namespace" schemaLocation="http://www.w3.org/2001/xml.xsd"/>

            <!-- import cmd-envelop for the use of the general CMD attributes -->
            <xs:import namespace="http://www.clarin.eu/cmd/1" schemaLocation="{$cmd-envelop}"/>


            <!--  first create complex types for valueschemes (not inline) -->
            <xsl:call-template name="CreateComplexTypes"/>

            <!--Start with processing the root component once and then process everything else recursively-->
            <xsl:apply-templates select="Component"/>

        </xs:schema>

    </xsl:template>

    <xsl:template match="*" mode="Header">
        <xsl:element name="cmd:{name()}">
            <xsl:value-of select="text()"/>
            <xsl:apply-templates select="*" mode="Header"/>
        </xsl:element>
    </xsl:template>

    <xsl:template name="CreateComplexTypes">
        <xsl:apply-templates select="Component" mode="types"/>
    </xsl:template>

    <!-- create a unique identifier from the current element -->
    <xsl:function name="cmd:getComponentId">
        <xsl:param name="node"/>
        
        <xsl:text>-</xsl:text>
        
        <xsl:choose>
            
            <!-- deeper recursion needed -->
            <xsl:when test="$node[empty(@ComponentRef)]">
                
                <xsl:choose>
                    <!-- element has name, add it to the type name and recurse upwards in the tree -->
                    <xsl:when test="$node/self::Element">
                        <xsl:value-of select="$node/@name"/>
                    </xsl:when>
                    <!-- "worst" case: embedded anonymous component without ComponentId: use the xpath -->
                    <xsl:when test="$node/self::Component">
                        <xsl:value-of select="count($node/preceding-sibling::*)"/>
                    </xsl:when>
                </xsl:choose>
                
                <!-- recursive call -->
                <xsl:value-of select="cmd:getComponentId($node/..)"/>
                
            </xsl:when>
            
            <!-- end of recursion: component has ComponentId -->
            <xsl:otherwise>
                <xsl:value-of select="replace($node/@ComponentRef, ':', '.')"/>
            </xsl:otherwise>
            
        </xsl:choose>
        
    </xsl:function>

    <!-- generate types -->

    <!-- skip all text nodes -->
    <xsl:template match="text()" mode="types"/>

    <!-- first pass: create the complex types on top of the resulting XSD -->
    <xsl:template match="Element/ValueScheme[exists(Vocabulary/enumeration) or exists(pattern)]" mode="types">
        
        <!-- only handle the ValueScheme if this is the first occurence of the Component -->
        <xsl:variable name="Component" select="ancestor::Component[exists(@ComponentRef)]"/>
        <xsl:if test="empty($Component/preceding::Component[@ComponentRef=$Component/@ComponentRef])">
            
            <!-- create a unique suffix (the path to the element) to ensure the unicity of the types to be created -->
            <xsl:variable name="uniquePath" select="cmd:getComponentId(..)"/>
            
            <!-- first auto-generate a name for the simpletype to be extended -->
            <xs:simpleType name="simpletype{$uniquePath}">
                <xs:restriction base="xs:string">
                    <xsl:apply-templates select="pattern"/>
                    <xsl:apply-templates select="Vocabulary/enumeration"/>
                </xs:restriction>
            </xs:simpleType>
            
            <!--  then auto-derive a complextype for the attributes -->
            <xs:complexType name="complextype{$uniquePath}">
                <xs:simpleContent>
                    <xs:extension base="cmdp:simpletype{$uniquePath}">
                        <!-- now look at the attribute list of the Element parent of this ValueScheme-->
                        <xsl:apply-templates select="parent::Element/AttributeList/Attribute"/>
                        <!-- an element can refer to an entry in a closed external vocabulary -->
                        <xsl:if test="parent::Element/ValueScheme/Vocabulary/@URI">
                            <xs:attribute ref="cmd:ValueConceptLink"/>
                        </xsl:if>
                    </xs:extension>
                </xs:simpleContent>
            </xs:complexType>
        </xsl:if>

    </xsl:template>

    <!-- Stop types -->

    <!-- convert all components -->
    <xsl:template match="Component">

        <xs:element name="{@name}">
            
            <xsl:call-template name="annotations"/>

            <xsl:apply-templates select="@ConceptLink"/>
            <xsl:apply-templates select="@CardinalityMin"/>
            <xsl:apply-templates select="@CardinalityMax"/>
            
            <xs:annotation>
                <xsl:apply-templates select="Documentation"/>
            </xs:annotation>
            
            <xs:complexType>

                <xs:sequence>
                    <!-- process all elements at this level -->
                    <xsl:apply-templates select="./Element"/>
                    <!-- process all components at one level deeper (recursive call) -->
                    <xsl:apply-templates select="./Component"/>
                </xs:sequence>
                
                <!--  allow @xml:base as a residue of XInclude processing -->
                <xs:attribute ref="xml:base"/>

                <!-- @ref to the resource proxy -->
                <xs:attribute ref="cmd:ref"/>
                
                <!-- allow @ComponentId referring to the Component it instantiates -->
                <xsl:if test="exists(@ComponentRef)">
                    <xs:attribute ref="cmd:ComponentId" fixed="{@ComponentRef}"/>
                </xsl:if>

                <xsl:apply-templates select="./AttributeList/Attribute"/>

            </xs:complexType>

        </xs:element>

    </xsl:template>

    <!-- Process all Elements, its attributes and children -->

    <!-- Highest complexity: a restrictive ValueScheme and possibly attributes, link to the type we created during the preprocessing of the ValueScheme -->
    <xsl:template match="Element[./ValueScheme[exists(Vocabulary/enumeration) or exists(pattern)]]" priority="3">
        <xs:element name="{@name}">

            <xsl:apply-templates select="@ConceptLink"/>
            <xsl:apply-templates select="@CardinalityMin"/>
            <xsl:apply-templates select="@CardinalityMax"/>
            <xsl:apply-templates select="ValueScheme"/>

            <!-- process all autovalue and cues attributes -->
            <xsl:call-template name="annotations"/>
            
            <xs:annotation>
                <xsl:apply-templates select="Documentation"/>
            </xs:annotation>
            
        </xs:element>
    </xsl:template>

    <!-- Medium complexity: attributes (or Multilingual field) but no restrictive ValueScheme, can be arranged inline -->
    <xsl:template match="Element[./AttributeList or ./@Multilingual='true']" priority="2">
        <xs:element name="{@name}">

            <xsl:apply-templates select="@Multilingual"/>
            <xsl:apply-templates select="@ConceptLink"/>
            <xsl:apply-templates select="@CardinalityMin"/>
            <xsl:apply-templates select="@CardinalityMax"/>

            <!-- process all autovalue and cues attributes -->
            <xsl:call-template name="annotations"/>

            <xs:annotation>
                <xsl:apply-templates select="Documentation"/>
            </xs:annotation>
            
            <xs:complexType>
                <xs:simpleContent>
                    <xs:extension base="{concat('xs:',(@ValueScheme,'string')[1])}">
                        <xsl:apply-templates select="./AttributeList/Attribute"/>
                        <xsl:if test="./@Multilingual='true'">
                            <xs:attribute ref="xml:lang"/>
                        </xsl:if>
                        <!-- an element can refer to an entry in an open external vocabulary -->
                        <xsl:if test="exists(./ValueScheme/@URI)">
                            <xs:attribute ref="cmd:ValueConceptLink"/>
                        </xsl:if>
                    </xs:extension>
                </xs:simpleContent>
            </xs:complexType>
        </xs:element>
    </xsl:template>

    <!-- Simple case: no attributes and no restrictive ValueScheme, 1-to-1 transform to an xs:element, just rename element and attributes -->
    <xsl:template match="Element" priority="1">
        <xs:element>

            <xsl:apply-templates select="@name"/>
            <xsl:apply-templates select="@ConceptLink"/>
            <xsl:apply-templates select="@CardinalityMin"/>
            <xsl:apply-templates select="@CardinalityMax"/>
            <xsl:if test="empty(./ValueScheme/@URI)">
                <xsl:apply-templates select="@Multilingual"/>
                <xsl:attribute name="type">
                    <xsl:value-of select="concat('xs:',(@ValueScheme,'string')[1])"/>
                </xsl:attribute>
            </xsl:if>
            
            <!-- process all autovalue and cues attributes -->
            <xsl:call-template name="annotations"/>
            <xs:annotation>
                <xsl:apply-templates select="Documentation"/>
            </xs:annotation>
            
            <xsl:if test="exists(./ValueScheme/@URI)">
                <xs:complexType>
                    <xs:simpleContent>
                        <xs:extension base="{concat('xs:',(@ValueScheme,'string')[1])}">
                            <xsl:if test="./@Multilingual='true'">
                                <xs:attribute ref="xml:lang"/>
                            </xsl:if>
                            <!-- an element can refer to an entry in an open external vocabulary -->
                            <xsl:if test="exists(./ValueScheme/@URI)">
                                <xs:attribute ref="cmd:ValueConceptLink"/>
                            </xsl:if>
                        </xs:extension>
                    </xs:simpleContent>
                </xs:complexType>
            </xsl:if>
        </xs:element>
    </xsl:template>

    <!-- end of Element templates -->

    <!-- second pass, now link to the earlier created ComplexType definition -->
    <xsl:template match="ValueScheme">
        <xsl:variable name="uniquePath" select="cmd:getComponentId(..)"/>
        <xsl:attribute name="type">
            <xsl:text>cmdp:complextype</xsl:text>
            <xsl:value-of select="$uniquePath"/>
        </xsl:attribute>
    </xsl:template>

    <!-- Convert the AttributeList into real XSD attributes -->
    <xsl:template match="AttributeList/Attribute">
        <xs:attribute name="{@name}">
            
            <!-- a mandatory attribute? -->
            <xsl:if test="@Required='true'">
                <xsl:attribute name="use" select="'required'"/>
            </xsl:if>

            <!-- Add a cmd:ConceptLink if a ConceptLink element is found -->
            <xsl:if test="normalize-space(@ConceptLink)!=''">
                <xsl:attribute name="cmd:ConceptLink">
                    <xsl:value-of select="@ConceptLink"/>
                </xsl:attribute>
            </xsl:if>

            <!-- add some extra stuff if we have a CV attribute -->
            <xsl:choose>

                <!-- complex situation: CV or regex -->
                <xsl:when test="exists(./ValueScheme/((Vocabulary/enumeration)|pattern))">

                    <xs:annotation>
                        <xsl:apply-templates select="Documentation"/>
                    </xs:annotation>

                    <xs:simpleType>
                        <xs:restriction base="xs:string">
                            <!-- now use general rules for enumeration or pattern -->
                            <xsl:apply-templates select="./ValueScheme/*"/>
                        </xs:restriction>
                    </xs:simpleType>
                </xsl:when>

                <!-- simple situation: just a basic type -->
                <xsl:otherwise>
                    <xsl:attribute name="type">
                        <xsl:value-of select="concat('xs:',(@ValueScheme,'string')[1])"/>
                    </xsl:attribute>
                    
                    <xs:annotation>
                        <xsl:apply-templates select="Documentation"/>
                    </xs:annotation>
                    
                </xsl:otherwise>

            </xsl:choose>

        </xs:attribute>
    </xsl:template>

    <!-- Convert patterns -->
    <xsl:template match="pattern">
        <xs:pattern value="{self::node()}"/>
    </xsl:template>

    <!-- Convert enumerations -->
    <xsl:template match="Vocabulary">
        <xsl:apply-templates select="@*|node()"/>
    </xsl:template>
    
    <xsl:template match="enumeration">
        <xsl:for-each select="item">
            <xs:enumeration value="{node()}">
                <xsl:apply-templates select="./@ConceptLink"/>
                <xsl:apply-templates select="./@AppInfo"/>
            </xs:enumeration>
        </xsl:for-each>
    </xsl:template>

    <!--  default action: keep the attributes like they are -->
    <xsl:template match="@*|node()">
        <xsl:copy/>
    </xsl:template>

    <!-- except for those attributes we want to be renamed -->
    <xsl:template match="@CardinalityMin">
        <xsl:attribute name="minOccurs">
            <xsl:value-of select="."/>
        </xsl:attribute>
    </xsl:template>

    <xsl:template match="@CardinalityMax">
        <xsl:attribute name="maxOccurs">
            <xsl:value-of select="."/>
        </xsl:attribute>
    </xsl:template>
    
    <!-- the root component can't have cardinality constraints -->
    <xsl:template match="ComponentSpec/Component/@CardinalityMin" priority="1"/>
    
    <xsl:template match="ComponentSpec/Component/@CardinalityMax"/>
    
    <!-- start multilinguality part -->

    <!-- if the multilingual attribute is there and the field has the (default) type string, allow multiple occurrences -->
    <xsl:template match="@Multilingual[(empty(../@ValueScheme) and empty(../ValueScheme)) or ../@ValueScheme='string'][. = 'true'] ">
        <xsl:attribute name="maxOccurs">
            <xsl:value-of>unbounded</xsl:value-of>
        </xsl:attribute>
    </xsl:template>

    <xsl:template match="@Multilingual">
        <!-- do nothing - only influences maxOccurs if it is true and if it is a a string element -->
    </xsl:template>

    <xsl:template match="@CardinalityMax[../@Multilingual='true'][(empty(../@ValueScheme) and empty(../ValueScheme)) or ../@ValueScheme='string']">
        <!-- do nothing - maxOccurs should be set by Multilingual rule for strings -->
    </xsl:template>

    <!-- end multilinguality part -->

    <!-- Add a @cmd:ConceptLink if a ConceptLink attribute is found -->
    <xsl:template match="@ConceptLink">
        <xsl:attribute name="cmd:ConceptLink">
            <xsl:value-of select="."/>
        </xsl:attribute>
    </xsl:template>

    <xsl:template match="@AppInfo">
        <xsl:attribute name="cmd:label">
            <xsl:value-of select="."/>
        </xsl:attribute>
    </xsl:template>

    <xsl:template match="Vocabulary/@URI">
        <xsl:attribute name="cmd:Vocabulary">
            <xsl:value-of select="."/>
        </xsl:attribute>
    </xsl:template>

    <xsl:template match="@ValueProperty|@ValueLanguage">
        <xsl:attribute name="cmd:{local-name()}">
            <xsl:value-of select="."/>
        </xsl:attribute>
    </xsl:template>
    
    <xsl:template match="Documentation">
        <xs:documentation>
            <xsl:copy-of select="@xml:lang"/>
            <xsl:value-of select="."/>
        </xs:documentation>
    </xsl:template>

    <xsl:template match="@AutoValue">
        <xsl:attribute name="cmd:AutoValue">
            <xsl:value-of select="."/>
        </xsl:attribute>
    </xsl:template>
    
    <xsl:template match="@cue:*">
        <xsl:copy-of select="."/>
    </xsl:template>
    
    <xsl:template name="annotations">
        <xsl:apply-templates select="@AutoValue"/>
        <xsl:apply-templates select="@cue:*"/>
    </xsl:template>

</xsl:stylesheet>
