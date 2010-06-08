<?xml version="1.0" encoding="UTF-8"?>

<!-- 
    $Rev: 484 $ 
    $Date$ 
-->

<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="2.0"
    xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:dcr="http://www.isocat.org"
    xmlns:ann="http://www.clarin.eu"
    >
    <xsl:strip-space elements="*"/>
    <xsl:include href="comp2schema-header.xsl"/>
    <!-- note: the automatic chaining with clean-xsd.xsl only works with the Saxon XSLT processor, otherwise you'll have to do this manually (or use e.g the Xalan pipeDocument tag) -->
    <xsl:output method="xml" version="1.0" encoding="UTF-8" indent="yes" saxon:next-in-chain="cleanup-xsd.xsl" xmlns:saxon="http://saxon.sf.net/"/>

    <!-- Start includes -->

    <!-- resolve includes -->
    <xsl:template match="@*|node()" mode="include">
        <xsl:copy>
            <xsl:apply-templates select="@*|node()" mode="include"/>
        </xsl:copy>
    </xsl:template>

    <xsl:template match="CMD_Component[@filename]" mode="include">
        <!-- some of the outer CMD_Component attributes can overwrite the inner CMD_Component attributes -->
        <xsl:variable name="outer-attr" select="@CardinalityMin|@CardinalityMax"/>
        <xsl:for-each select="document(@filename)/CMD_ComponentSpec/CMD_Component">
            <xsl:variable name="inner-attr" select="@*"/>
            <xsl:copy>
                <xsl:apply-templates select="$outer-attr" mode="include"/>
                <xsl:apply-templates
                    select="$inner-attr[not(node-name(.) = $outer-attr/node-name(.))]"
                    mode="include"/>
                <xsl:apply-templates select="node()" mode="include"/>
            </xsl:copy>
        </xsl:for-each>
    </xsl:template>

    <!-- Stop includes -->

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
    <xsl:template match="/CMD_ComponentSpec">

        <xs:schema xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:dcr="http://www.isocat.org">

            <!--  first create complex types for valueschemes (not inline) -->
            <xsl:call-template name="CreateComplexTypes"/>

            <xs:element name="CMD">
                <xs:complexType>
                    <xs:sequence>

                        <!-- Produce (fixed) header elements (description and resources)-->
                        <xsl:call-template name="PrintHeader"/>

                        <!-- Then generate the components -->
                        <xs:element name="Components">

                            <xs:complexType>
                                <xs:sequence>
                                    <!--Start with processing the root component once and then process everything else recursively-->
                                    <xsl:apply-templates select="/CMD_ComponentSpec/CMD_Component"/>
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
        <xsl:apply-templates select="CMD_Component" mode="types"/>
    </xsl:template>


    <!-- Start types -->

    <!-- workaround to prevent junk in complex type definitions -->
    <!--<xsl:template match="AttributeList" mode="preProcess"/>-->

    <!-- skip all text nodes -->
    <xsl:template match="text()" mode="types"/>

    <!-- first pass: create the complex types on top of the resulting XSD -->
    <xsl:template match="ValueScheme" mode="types">
        <!-- create a unique suffix (the path to the element) to ensure the unicity of the types to be created -->

        <!-- ignore when this ValueScheme is descendant of an Attribute as we do not allow CV-attributes in a CV-list -->
        <xsl:if test="not(../../Attribute)">

            <xsl:variable name="uniquePath">
                <xsl:call-template name="printComponentId">
                    <!-- start from the CMD_Element above and go upwards in the tree -->
                    <xsl:with-param name="node" select=".."/>
                </xsl:call-template>
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


        </xsl:if>

    </xsl:template>



    <!-- Stop types -->

    <!-- create a unique identifier (the path of the name of the ancestor elements) from the current ValueScheme element -->
    <xsl:template name="printUniquePath">
        <xsl:for-each select="ancestor::*">
            <xsl:if test="string(./@name)">
                <xsl:text>-</xsl:text>
                <xsl:value-of select="./attribute::name"/>
            </xsl:if>
        </xsl:for-each>
    </xsl:template>

    <xsl:template name="printComponentId">
        <xsl:param name="node"/>
        <xsl:text>-</xsl:text>
        
        <xsl:choose>
        
            <!-- deeper recursion needed -->
            <xsl:when test="$node[not(@ComponentId)]">
                
                <xsl:choose>
                    <!-- element has name, add it to the type name and recurse upwards in the tree -->
                    <xsl:when test="name($node) = 'CMD_Element'">
                        <xsl:value-of select="$node/attribute::name"/>
                    </xsl:when>
                    <!-- "worst" case: embedded anonymous component without ComponentId: use the xpath -->
                    <xsl:when test="name($node)  = 'CMD_Component'">
                        <xsl:value-of select="count($node/preceding-sibling::*)"/>
                    </xsl:when>
                </xsl:choose>
                
                <!-- recursive call -->
                <xsl:call-template name="printComponentId">
                    <xsl:with-param name="node" select="$node/.."/>
                </xsl:call-template>
            
            </xsl:when>

            <!-- end of recursion: component has ComponentId -->
            <xsl:otherwise>
                <xsl:value-of select="replace($node/attribute::ComponentId, ':', '.')"/>
            </xsl:otherwise>

        </xsl:choose>

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
                <xsl:apply-templates select="./AttributeList/Attribute"/>
                <xsl:if test="@ComponentId">
                    <xs:attribute name="ComponentId" type="xs:anyURI" fixed="{@ComponentId}"/>
                </xsl:if>
            </xs:complexType>


        </xs:element>

    </xsl:template>

    <!-- Process all CMD_Elements, its attributes and children -->
    <xsl:template match="CMD_Element">

        <xsl:choose>

            <!-- Highest complexity: both attributes and a valuescheme, link to the type we created during the preprocessing of the ValueScheme -->
            <xsl:when test="./AttributeList and ./ValueScheme">
                <xs:element name="{@name}">

                    <!-- process all Documentation and DisplayPriority attributes -->
                    <xsl:call-template name="annotations"/>

                    <xsl:apply-templates select="@ConceptLink"/>
                    <xsl:apply-templates select="@CardinalityMin"/>
                    <xsl:apply-templates select="@CardinalityMax"/>
                    <xsl:apply-templates select="ValueScheme"/>                    
                    
                </xs:element>
            </xsl:when>

            <!-- Medium complexity: attributes but no valuescheme, can be arranged inline -->
            <xsl:when test="./AttributeList and not(./ValueScheme)">
                <xs:element name="{@name}">

                    <xsl:apply-templates select="@ConceptLink"/>
                    <xsl:apply-templates select="@CardinalityMin"/>
                    <xsl:apply-templates select="@CardinalityMax"/>

                    <!-- process all Documentation and DisplayPriority attributes -->
                    <xsl:call-template name="annotations"/>

                    <!-- <xsl:apply-templates select= "and(not(@type) and @*)"/> -->
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

                    <xsl:apply-templates
                        select="@*[name() != 'Documentation' and name() != 'DisplayPriority'] | node()"/>
                    <!-- process all Documentation and DisplayPriority attributes -->
                    <xsl:call-template name="annotations"/>

                </xsl:element>
            </xsl:otherwise>

        </xsl:choose>

    </xsl:template>

    <!-- second pass, now link to the earlier created complextype definition -->
    <xsl:template match="ValueScheme">
        <xsl:variable name="uniquePath">
            <xsl:call-template name="printComponentId">
                <!-- start from the CMD_Element above and go upwards in the tree -->
                <xsl:with-param name="node" select=".."/>
            </xsl:call-template>
        </xsl:variable>
        
        <xsl:attribute name="type">
            <xsl:text>complextype</xsl:text>
            <xsl:value-of select="$uniquePath"></xsl:value-of>
            
            <!--
                strange but this does not work!
                <xsl:call-template name="printComponentId">
                <xsl:with-param name="node">
                    <xsl:value-of select="."/>
                </xsl:with-param>
            </xsl:call-template>
            -->
        
        </xsl:attribute>
    </xsl:template>

    <!-- Convert the AttributeList into real XSD attributes -->
    <xsl:template match="AttributeList/Attribute">
        <xs:attribute name="{./Name}">

            <!-- add some extra stuff if we have a CV attribute -->
            <xsl:choose>

                <!-- complex situation: CV or regex -->
                <xsl:when test="./ValueScheme">
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
                        <xsl:value-of select="concat('xs:',./Type)"/>
                    </xsl:attribute>
                </xsl:otherwise>

            </xsl:choose>


        </xs:attribute>
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
                <xsl:apply-templates select="./@AppInfo"/>
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

    <xsl:template match="@AppInfo">
        <xs:annotation>
            <xs:appinfo>
                <xsl:value-of select="."/>
            </xs:appinfo>
        </xs:annotation>
    </xsl:template>


    <xsl:template match="@ValueScheme">
        <xsl:attribute name="type">
            <xsl:value-of select="concat('xs:',.)"/>
        </xsl:attribute>
    </xsl:template>

    <xsl:template match="@Documentation">
        <xsl:attribute name="ann:documentation">
            <xsl:value-of select="."/>
        </xsl:attribute>
        <!--<xs:documentation><xsl:value-of select="."/></xs:documentation>-->
    </xsl:template>

    <xsl:template match="@DisplayPriority">
        <xsl:attribute name="ann:displaypriority">
            <xsl:value-of select="."/>
        </xsl:attribute>
        <!--<xs:appinfo><DisplayPriority><xsl:value-of select="."/></DisplayPriority></xs:appinfo>-->
    </xsl:template>

    <xsl:template name="annotations">
        <xsl:if test="@Documentation or @DisplayPriority">
            <!--<xs:annotation>-->
            <xsl:apply-templates select="@Documentation"/>
            <xsl:apply-templates select="@DisplayPriority"/>
            <!--</xs:annotation>-->
        </xsl:if>
    </xsl:template>


</xsl:stylesheet>