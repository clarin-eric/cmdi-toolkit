<?xml version="1.0" encoding="UTF-8"?>

<!-- 
$Revision: 15119 $
$Date: 2009-05-26 18:00:29 +0200 (Tue, 26 May 2009) $
-->

<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="2.0"
    xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:dcr="http://www.isocat.org">
    <xsl:strip-space elements="*"/>
    <xsl:include href="comp2schema-header.xsl"/>
    <xsl:output method="xml" version="1.0" encoding="UTF-8" indent="yes"/>
   
    <xsl:template match="/CMD_ComponentSpec">

        <xs:schema xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:dcr="http://www.isocat.org">

            <!--  first create complex types for valueschemes (not inline) -->
            <xsl:call-template name="CreateComplexTypes"/>

            <xs:element name="CMD">
                <xs:complexType>
                    <xs:sequence>

                        <!--  Produce (fixed) header elements (description and resources)-->
                        <xsl:call-template name="PrintHeader"/>

                        <!-- Then generate the components -->
                        <xs:element name="Components">                            
                            
                            <xs:complexType>
                                <xs:sequence>
                                    <!--Start with processing the root component once and then process everything else recursively-->
                                    <xsl:apply-templates select="/CMD_ComponentSpec/CMD_Component"/>
                                    <!--<xsl:apply-templates select="CMD_ComponentList"/>-->
                                </xs:sequence>
                            </xs:complexType>
                        </xs:element>

                        <!-- Generate the footer -->
                    </xs:sequence>
                </xs:complexType>
            </xs:element>
        </xs:schema>

    </xsl:template>


    <xsl:template name="CreateComplexTypes">
        <xsl:apply-templates select=".//CMD_Component" mode="preProcess"/>
    </xsl:template>


    <!-- Start PreProcess --> 

    <!-- search for valueschemes in the included components -->
    <xsl:template match="CMD_Component[@filename]" mode="preProcess">
        <!-- recursively inspect all CMD_Components that are included -->    
        <xsl:apply-templates select="document(@filename)/CMD_ComponentSpec/CMD_Component/.//CMD_Component" mode="preProcess"/>    
        <xsl:apply-templates select="document(@filename)/CMD_ComponentSpec/CMD_Component/.//ValueScheme" mode="preProcess"/>
    </xsl:template>
    
    <!-- workaround to prevent junk in complex type definitions -->
    <!--<xsl:template match="AttributeList" mode="preProcess"/>-->
       
    <!-- first pass: create the complex types on top of the resulting XSD -->
    <xsl:template match="ValueScheme" mode="preProcess">
        <!-- create a unique suffix (the path to the element) to ensure the unicity of the types to be created -->
        <xsl:variable name="uniquePath">
            <xsl:call-template name="printUniquePath"/>
        </xsl:variable>
        
        <!-- first auto-generate a name for the simpletype to be extended -->
        <xs:simpleType name="simpletype{$uniquePath}">
            <xs:restriction base="xs:string">
                <xsl:apply-templates select="pattern"/>
                <xsl:apply-templates select="enumeration"/>
            </xs:restriction>
        </xs:simpleType>
        
        <!--  then auto-derive a complextype for the attributes -->
        <xs:complexType name="complextype{$uniquePath}">
            <xs:simpleContent>
                <xs:extension base="simpletype{$uniquePath}">
                    <!-- now look at the attribute list of the CMD_Element parent of this ValueScheme-->
                    <xsl:apply-templates select="parent::node()/AttributeList/Attribute"/>
                    <!--<xs:attribute name="attributeName" type="xs:anyURI"/>-->
                </xs:extension>
            </xs:simpleContent>
        </xs:complexType>
    </xsl:template>
    
    <!-- Stop PreProcess -->
    
    
    <!-- Expand the included components (those with a filename attribute) and apply the default templates afterwards -->
    <xsl:template match="CMD_Component[@filename]">
        
        <!-- TODO: look for more elegant construction -->
        <xsl:choose>
            <xsl:when test="@CardinalityMin and @CardinalityMax">
                <xsl:apply-templates select="document(@filename)/CMD_ComponentSpec/CMD_Component">
                    <xsl:with-param name="MinOccurs" select="@CardinalityMin"/>
                    <xsl:with-param name="MaxOccurs" select="@CardinalityMax"/>
                </xsl:apply-templates>
            </xsl:when>
            <xsl:otherwise>
                <xsl:choose>
                    <xsl:when test="@CardinalityMin">
                        <xsl:apply-templates select="document(@filename)/CMD_ComponentSpec/CMD_Component">
                            <xsl:with-param name="MinOccurs" select="@CardinalityMin"/>
                        </xsl:apply-templates>
                    </xsl:when>
                    <xsl:when test="@CardinalityMax">
                        <xsl:apply-templates select="document(@filename)/CMD_ComponentSpec/CMD_Component">
                            <xsl:with-param name="MinOccurs" select="@CardinalityMax"/>
                        </xsl:apply-templates>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:apply-templates select="document(@filename)/CMD_ComponentSpec/CMD_Component"/>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    <!-- create a unique identifier (the path of the name of the ancestor elements) from the current ValueScheme element -->
    <xsl:template name="printUniquePath">
        <xsl:for-each select="ancestor::*">
            <xsl:if test="string(./@name)">
                <xsl:text>-</xsl:text>
                <xsl:value-of select="./attribute::name"/>
            </xsl:if>
        </xsl:for-each>
    </xsl:template>

    <!-- convert all components -->
    <xsl:template match="CMD_Component">
        <!--  use override values if specified in parent <CMD_Component filename=...> , otherwise use default cardinality for this component -->
        <xsl:param name="MinOccurs" select="@CardinalityMin"/>
        <xsl:param name="MaxOccurs" select="@CardinalityMax"/>
        
        <xs:element name="{@name}">
            <xsl:if test="$MinOccurs">
                <xsl:attribute name="minOccurs">
                    <xsl:value-of select="$MinOccurs"/>
                </xsl:attribute>
            </xsl:if>
            <xsl:if test="$MaxOccurs">
                <xsl:attribute name="maxOccurs">
                    <xsl:value-of select="$MaxOccurs"/>
                </xsl:attribute>
            </xsl:if>
            <!-- Add a dcr:datcat if a ConceptLink attribute is found -->
            <xsl:apply-templates select="./@ConceptLink"/>
            <xs:complexType>
                <xs:sequence>
                    <!-- process all elements at this level -->
                    <xsl:apply-templates select="./CMD_Element"/>
                    <!-- process all components at one level deeper (recursive call) -->
                    <xsl:apply-templates select="./CMD_Component"/>
                </xs:sequence>
                <xs:attribute name="ref" type="xs:IDREF"/>
            </xs:complexType>
        </xs:element>

    </xsl:template>

    <!-- Process all CMD_Elements, its attributes and children -->
    <xsl:template match="CMD_Element">
        <xsl:choose>

            <!-- Highest complexity: both attributes and a valuescheme, link to the type we created during the preprocessing of the ValueScheme -->
            <xsl:when test="./AttributeList and ./ValueScheme">
                <xs:element name="{@name}">
                    <xsl:apply-templates select="./ValueScheme"/>
                </xs:element>
            </xsl:when>

            <!-- Medium complexity: attributes but no valuescheme, can be arranged inline -->
            <xsl:when test="./AttributeList and not(./ValueScheme)">
                <xs:element name="{@name}">
                    <xs:complexType>
                        <xs:simpleContent>
                            <xs:extension base="{concat('xs:',@ValueScheme)}">
                                <xsl:apply-templates select="./AttributeList/Attribute"/>
                            </xs:extension>
                        </xs:simpleContent>
                    </xs:complexType>
                </xs:element>
            </xsl:when>

            <!-- Simple case: no attributes and no value scheme, 1-to-1 transform to an xs:element, just rename element and attributes -->
            <xsl:otherwise>
                <xsl:element name="xs:element">
                    <xsl:apply-templates select="@* | node()"/>
                </xsl:element>
            </xsl:otherwise>

        </xsl:choose>

    </xsl:template>

    <!-- second pass, now link to the earlier created complextype definition -->
    <xsl:template match="ValueScheme">
        <xsl:attribute name="type">
            <xsl:text>complextype</xsl:text>
            <xsl:call-template name="printUniquePath"/>
        </xsl:attribute>
        
    </xsl:template>

    <!-- Convert the AttributeList into real XSD attributes -->
    <xsl:template match="AttributeList/Attribute">
        <xs:attribute name="{./Name}" type="xs:{./Type}"/>
    </xsl:template>

    <!-- Convert patterns -->
    <xsl:template match="pattern">
        <xs:pattern value="{self::node()}"/>
    </xsl:template>

    <!-- Convert enumerations -->
    <xsl:template match="enumeration">
        
        <xsl:for-each select="item">
            <xs:enumeration value="{node()}">
                <!-- Add a dcr:datcat if a ConceptLink attribute is found -->
                <xsl:apply-templates select="./@ConceptLink"/>
            </xs:enumeration>
            <!-- dcr:datcat="{@ConceptLink}"/>-->
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

    <xsl:template match="@ConceptLink">
        <xsl:attribute name="dcr:datcat">
            <xsl:value-of select="."/>
        </xsl:attribute>
    </xsl:template>

    <xsl:template match="@ValueScheme">
        <xsl:attribute name="type">
            <xsl:value-of select="concat('xs:',.)"/>
        </xsl:attribute>
    </xsl:template>

</xsl:stylesheet>