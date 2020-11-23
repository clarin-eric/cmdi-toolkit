<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:cue="http://www.clarin.eu/cmd/cues/1"
    xmlns:cue_old="http://www.clarin.eu/cmdi/cues/1"
    exclude-result-prefixes="xs"
    version="2.0">

    <xsl:param name="cmd-component-xsd" select="'https://infra.clarin.eu/CMDI/1.1/general-component-schema.xsd'"/>
    
    <xsl:param name="escape" select="'ccmmddii_'"/>
    
    <!-- identity copy -->
    <xsl:template match="@*">
        <xsl:copy/>
    </xsl:template>
    
    <xsl:template match="node()">
        <xsl:copy>
            <xsl:apply-templates select="@*|node()"/>
        </xsl:copy>
    </xsl:template>

    <!-- refer to cmd-component.xsd -->
    <xsl:template match="@xsi:noNamespaceSchemaLocation" priority="1">
        <xsl:attribute name="xsi:noNamespaceSchemaLocation" select="$cmd-component-xsd"/>
    </xsl:template>

    <!-- add CMD_ prefix -->
    <xsl:template match="ComponentSpec" priority="1">
        <CMD_ComponentSpec>
            <xsl:apply-templates select="@*|node()"/>
        </CMD_ComponentSpec>
    </xsl:template>

    <xsl:template match="Component" priority="1">
        <CMD_Component>
            <xsl:apply-templates select="@*"/>
            <xsl:apply-templates select="node() except Documentation"/>
        </CMD_Component>
    </xsl:template>
    
    <xsl:template match="Element" priority="1">
        <CMD_Element>
            <xsl:apply-templates select="@*"/>
            <xsl:apply-templates select="Documentation"/>
            <xsl:apply-templates select="node() except Documentation"/>
        </CMD_Element>
    </xsl:template>
    
    <!-- remove CDM version attributes -->
    <xsl:template match="ComponentSpec/@CMDVersion"/>
    <xsl:template match="ComponentSpec/@CMDOriginalVersion"/>
    
    <!-- remove Status and friends -->
    <xsl:template match="Header/Status" priority="1"/>
    <xsl:template match="Header/StatusComment" priority="1"/>
    <xsl:template match="Header/Successor" priority="1"/>
    <xsl:template match="Header/DerivedFrom" priority="1"/>
    
    <!-- turn @ComponentRef into @ComponentId -->
    <xsl:template match="@ComponentRef">
        <xsl:attribute name="ComponentId" select="."/>
    </xsl:template>
    
    <!-- turn <Documentation/> into @Documentation -->
    <xsl:template match="Documentation" priority="1">
        <xsl:choose>
            <xsl:when test="exists(../Documentation[@xml:lang=('en','eng')])">
                <xsl:if test="@xml:lang=('en','eng') and empty(preceding-sibling::Documentation[@xml:lang=('en','eng')])">
                    <!-- first english documentation -->
                    <xsl:attribute name="Documentation" select="."/>
                </xsl:if>
            </xsl:when>
            <xsl:when test="exists(../Documentation[normalize-space(@xml:lang)=''])">
                <xsl:if test="normalize-space(@xml:lang)='' and empty(preceding-sibling::Documentation[normalize-space(@xml:lang)=''])">
                    <!-- first general documentation -->
                    <xsl:attribute name="Documentation" select="."/>
                </xsl:if>
            </xsl:when>
            <xsl:when test="empty(preceding-sibling::Documentation)">
                <!-- first documentation -->
                <xsl:attribute name="Documentation" select="."/>
            </xsl:when>
        </xsl:choose>
    </xsl:template>

    <!-- remove Vocabulary level, incl. attributes -->
    <xsl:template match="Vocabulary" priority="1">
        <xsl:apply-templates select="node()"/>
    </xsl:template>
    
    <!-- turn Attribute child elements into attributes -->
    <xsl:template match="Attribute" priority="1">
        <xsl:variable name="name">
            <xsl:choose>
                <xsl:when test="exists(parent::AttributeList/parent::Component) and Name=('ref','ComponentId')">
                    <xsl:message>WRN: <xsl:value-of select="/ComponentSpec/Header/ID"/>: user-defined ref and ComponentId attributes for a Component are not supported by CMDI 1.1! Adding the <xsl:value-of select="$escape"/> prefix</xsl:message>
                    <xsl:value-of select="concat($escape,@name)"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="@name"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <Attribute>
            <Name>
                <xsl:value-of select="$name"/>
            </Name>
            <xsl:if test="normalize-space(@ConceptLink)!=''">
                <ConceptLink>
                    <xsl:value-of select="@ConceptLink"/>
                </ConceptLink>
            </xsl:if>
            <xsl:if test="normalize-space(@ValueScheme)!=''">
                <Type>
                    <xsl:value-of select="@ValueScheme"/>
                </Type>
            </xsl:if>
            <!-- @Required is skipped -->
            <xsl:apply-templates select="node() except Documentation"/>
        </Attribute>
    </xsl:template>
    
    <!-- remove cue namespace for DisplayPriority -->
    <xsl:template match="@cue:DisplayPriority|@cue_old:DisplayPriority" priority="2">
        <xsl:attribute name="DisplayPriority">
            <xsl:value-of select="."/>
        </xsl:attribute>
    </xsl:template>
    
    <!-- remove other cue attributes -->
    <xsl:template match="@cue:*|@cue_old:*" priority="1"/>

</xsl:stylesheet>
