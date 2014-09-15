<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:cmd="http://www.clarin.eu/cmd/"
    exclude-result-prefixes="xs"
    version="2.0">
    
    <xsl:param name="cmd-envelop-xsd" select="'../../xsd/cmd-envelop.xsd'"/>
    <xsl:param name="cmd-profile-xsd" select="'../components/ToolService-1_2.xsd'"/>
    

    <!-- identity copy -->
    <xsl:template match="@*|node()">
        <xsl:copy>
            <xsl:apply-templates select="@*|node()"/>
        </xsl:copy>
    </xsl:template>
    
    <!-- try to determine the profile -->
    <xsl:variable name="profile">
        <xsl:variable name="header" select="/cmd:CMD/cmd:Header/cmd:MdProfile/replace(.,'.*(clarin.eu:cr1:p_[0-9]).*','$1')"/>
        <xsl:variable name="schema" select="/cmd:CMD/(@xsi:schemaLocation|@xsi:noNamespaceSchemaLocation)/replace(.,'.*(clarin.eu:cr1:p_[0-9]+).*','$1')"/>
        <xsl:if test="count($header) gt 1">
            <xsl:message>WRN: found more then one profile ID (<xsl:value-of select="string-join($header,',')"/>) in a cmd:MdProfile, will use the first one! </xsl:message>
        </xsl:if>
        <xsl:if test="count($schema) gt 1">
            <xsl:message>WRN: found more then one profile ID (<xsl:value-of select="string-join($schema,',')"/>) in a xsi:schemaLocation, will use the first one! </xsl:message>
        </xsl:if>
        <xsl:choose>
            <xsl:when test="exists($header) and exists($schema)">
                <xsl:if test="($header)[1] ne ($schema)[1]">
                    <xsl:message>WRN: the profile IDs found in cmd:MdProfile (<xsl:value-of select="($header)[1]"/>) and xsi:schemaLocation (<xsl:value-of select="($schema)[1]"/>), don't agree, will use the xsi:schemaLocation!</xsl:message>
                </xsl:if>
                <xsl:value-of select="($schema)[1]"/>
            </xsl:when>
            <xsl:when test="exists($header) and empty($schema)">
                <xsl:value-of select="($header)[1]"/>
            </xsl:when>
            <xsl:when test="empty($header) and exists($schema)">
                <xsl:value-of select="($schema)[1]"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:message terminate="yes">ERR: the profile ID can't be determined!</xsl:message>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:variable>
    
    <!-- CMD version becomes 1.2 -->
    <xsl:template match="/cmd:CMD/@CMDVersion">
        <xsl:attribute name="CMDVersion" select="'1.2'"/>
    </xsl:template>
    
    <!-- Create our own xsi:schemaLocation -->
    <xsl:template match="@xsi:schemaLocation"/>
    
    <xsl:template match="@xsi:noNamespaceSchemaLocation"/>
    
    <xsl:template match="cmd:CMD">
        <cmd:CMD>
            <xsl:namespace name="cmd" select="'http://www.clarin.eu/cmd/'"/>
            <xsl:namespace name="cmdp" select="$profile"/>
            <xsl:apply-templates select="@* except (@xsi:schemaLocation|@xsi:noNamespaceSchemaLocation)"/>
            <xsl:attribute name="xsi:schemaLocation">
                <xsl:text>http://www.clarin.eu/cmd/ </xsl:text>
                <xsl:value-of select="$cmd-envelop-xsd"/>
                <xsl:text> </xsl:text>
                <xsl:value-of select="$profile"/>
                <xsl:text> </xsl:text>
                <xsl:value-of select="$cmd-profile-xsd"/>
            </xsl:attribute>
            <xsl:apply-templates select="cmd:Header"/>
            <xsl:apply-templates select="cmd:Resources"/>
            <xsl:apply-templates select="cmd:Resources/cmd:IsPartOfList"/>
            <xsl:apply-templates select="cmd:Components"/>
        </cmd:CMD>
    </xsl:template>
    
    <!-- Make sure cmd:Header contains cmd:MdProfile -->
    <xsl:template match="cmd:Header">
        <cmd:Header>
            <xsl:apply-templates select="cmd:MdCreator"/>
            <xsl:apply-templates select="cmd:MdCreationDate"/>
            <xsl:apply-templates select="cmd:MdSelfLink"/>
            <cmd:MdProfile>
                <xsl:value-of select="$profile"/>
            </cmd:MdProfile>
            <xsl:apply-templates select="cmd:MdCollectionDisplayName"/>
        </cmd:Header>
    </xsl:template>
    
    <!-- Skip cmd:Resources/cmd:IsPartOfList -->
    <xsl:template match="cmd:Resources">
        <cmd:Resources>
            <xsl:apply-templates select="cmd:ResourceProxyList"/>
            <xsl:apply-templates select="cmd:JournalFileProxyList"/>
            <xsl:apply-templates select="cmd:ResourceRelationList"/>
        </cmd:Resources>
    </xsl:template>
    
    <!-- Reshape ResourceRelationList -->
    <xsl:template match="cmd:ResourceRelation/cmd:RelationType">
        <cmd:RelationType>
            <!-- take the string value, ignore deeper structure -->
            <xsl:value-of select="."/>
        </cmd:RelationType>
    </xsl:template>
    
    <xsl:template match="cmd:ResourceRelation/cmd:res1">
        <cmd:Resource>
            <xsl:apply-templates select="@*"/>
        </cmd:Resource>
    </xsl:template>
    
    <xsl:template match="cmd:ResourceRelation/cmd:res2">
        <cmd:Resource>
            <xsl:apply-templates select="@*"/>
        </cmd:Resource>
    </xsl:template>
    
    <!-- put envelop in the envelop namespace (it already is, but add the namespace) -->
    <xsl:template match="/cmd:CMD//*" priority="1">
        <xsl:element name="cmd:{local-name()}">
            <xsl:apply-templates select="@*|node()"/>
        </xsl:element>
    </xsl:template>
    
    <!-- put payload in the profile namespace -->
    <xsl:template match="cmd:Components//*" priority="2">
        <xsl:element namespace="{$profile}" name="cmdp:{local-name()}">
            <xsl:apply-templates select="@*|node()"/>
        </xsl:element>
    </xsl:template>
    
    <!-- move CMD attributes to the CMD namespace -->
    <xsl:template match="cmd:Components//@ref">
        <xsl:attribute name="cmd:ref" select="."/>
    </xsl:template>
    
    <xsl:template match="cmd:Components//@ComponentId">
        <xsl:attribute name="cmd:ComponentId" select="."/>
    </xsl:template>
    
    
</xsl:stylesheet>