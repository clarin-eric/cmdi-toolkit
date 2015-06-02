<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:cmd0="http://www.clarin.eu/cmd/"
    xmlns:cmd="http://www.clarin.eu/cmd/1"
    exclude-result-prefixes="xs cmd0"
    version="2.0">
    
    <xsl:param name="cmd-toolkit" select="'../../../../../main/resources/toolkit'"/>
    <xsl:param name="cmd-envelop-xsd" select="concat($cmd-toolkit,'/xsd/cmd-envelop.xsd')"/>
    <xsl:param name="cmd-uri" select="'http://www.clarin.eu/cmd/1'"/>
    <xsl:param name="cr-uri" select="'..'"/>
    
    <xsl:variable name="cmd-components" select="concat($cmd-uri,'/components')"/>
    <xsl:variable name="cmd-profiles" select="concat($cmd-uri,'/profiles')"/>
    <xsl:variable name="cr-profiles" select="concat($cr-uri,'/profiles')"/>
    <xsl:variable name="cr-extension-xsd" select="'-1_2.xsd'"/>

    <!-- identity copy -->
    <xsl:template match="@*|node()">
        <xsl:copy>
            <xsl:apply-templates select="@*|node()"/>
        </xsl:copy>
    </xsl:template>
    
    <!-- try to determine the profile -->
    <xsl:variable name="profile">
        <xsl:variable name="header" select="/cmd0:CMD/cmd0:Header/cmd0:MdProfile/replace(.,'.*(clarin.eu:cr1:p_[0-9]+).*','$1')"/>
        <xsl:variable name="schema" select="/cmd0:CMD/(@xsi:schemaLocation|@xsi:noNamespaceSchemaLocation)/replace(.,'.*(clarin.eu:cr1:p_[0-9]+).*','$1')"/>
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
    
    <!-- the profile specific uris -->
    <xsl:variable name="cmd-profile-uri" select="concat($cmd-profiles,'/',$profile)"/>
    <xsl:variable name="cr-profile-xsd" select="concat($cr-profiles,'/',$profile,$cr-extension-xsd)"/>
    
    <!-- CMD version becomes 1.2 -->
    <xsl:template match="/cmd0:CMD/@CMDVersion">
        <xsl:attribute name="CMDVersion" select="'1.2'"/>
    </xsl:template>
    
    <!-- Create our own xsi:schemaLocation -->
    <xsl:template match="@xsi:schemaLocation"/>
    
    <xsl:template match="@xsi:noNamespaceSchemaLocation"/>
    
    <xsl:template match="cmd0:CMD">
        <cmd:CMD>
            <xsl:namespace name="cmd" select="'http://www.clarin.eu/cmd/1'"/>
            <xsl:namespace name="cmdp" select="$cmd-profile-uri"/>
            <xsl:apply-templates select="@* except (@xsi:schemaLocation|@xsi:noNamespaceSchemaLocation)"/>
            <xsl:attribute name="xsi:schemaLocation">
                <xsl:value-of select="$cmd-uri"/>
                <xsl:text> </xsl:text>
                <xsl:value-of select="$cmd-envelop-xsd"/>
                <xsl:text> </xsl:text>
                <xsl:value-of select="$cmd-profile-uri"/>
                <xsl:text> </xsl:text>
                <xsl:value-of select="$cr-profile-xsd"/>
            </xsl:attribute>
            <xsl:apply-templates select="cmd0:Header"/>
            <xsl:apply-templates select="cmd0:Resources"/>
            <xsl:apply-templates select="cmd0:Resources/cmd0:IsPartOfList"/>
            <xsl:apply-templates select="cmd0:Components"/>
        </cmd:CMD>
    </xsl:template>
    
    <!-- Make sure cmd:Header contains cmd:MdProfile -->
    <xsl:template match="cmd0:Header">
        <cmd:Header>
            <xsl:apply-templates select="cmd0:MdCreator"/>
            <xsl:apply-templates select="cmd0:MdCreationDate"/>
            <xsl:apply-templates select="cmd0:MdSelfLink"/>
            <cmd:MdProfile>
                <xsl:value-of select="$profile"/>
            </cmd:MdProfile>
            <xsl:apply-templates select="cmd0:MdCollectionDisplayName"/>
        </cmd:Header>
    </xsl:template>
    
    <!-- Skip cmd:Resources/cmd:IsPartOfList -->
    <xsl:template match="cmd0:Resources">
        <cmd:Resources>
            <xsl:apply-templates select="cmd0:ResourceProxyList"/>
            <xsl:apply-templates select="cmd0:JournalFileProxyList"/>
            <xsl:apply-templates select="cmd0:ResourceRelationList"/>
        </cmd:Resources>
    </xsl:template>
    
    <!-- Reshape ResourceRelationList -->
    <xsl:template match="cmd0:ResourceRelation/cmd0:RelationType">
        <cmd:RelationType>
            <!-- take the string value, ignore deeper structure -->
            <xsl:value-of select="."/>
        </cmd:RelationType>
    </xsl:template>
    
    <xsl:template match="cmd0:ResourceRelation/cmd0:res1">
        <cmd:Resource>
            <xsl:apply-templates select="@*"/>
        </cmd:Resource>
    </xsl:template>
    
    <xsl:template match="cmd0:ResourceRelation/cmd0:res2">
        <cmd:Resource>
            <xsl:apply-templates select="@*"/>
        </cmd:Resource>
    </xsl:template>
    
    <!-- put envelop in the envelop namespace -->
    <xsl:template match="/cmd0:CMD//*" priority="1">
        <xsl:element name="cmd:{local-name()}">
            <xsl:apply-templates select="@*|node()"/>
        </xsl:element>
    </xsl:template>
    
    <!-- put payload in the profile namespace -->
    <xsl:template match="cmd0:Components//*" priority="2">
        <xsl:element namespace="{$cmd-profile-uri}" name="cmdp:{local-name()}">
            <xsl:apply-templates select="@*|node()"/>
        </xsl:element>
    </xsl:template>
    
    <!-- move CMD attributes to the CMD namespace -->
    <!-- TODO: @ref is allowed on elements, how to know if this is a element or a component with no children? -->
    <!--<xsl:template match="cmd0:Components//*[exists(*)]/@ref">-->
    <xsl:template match="cmd0:Components//@ref">
        <xsl:attribute name="cmd:ref" select="."/>
    </xsl:template>
    
    <xsl:template match="cmd0:Components//@ComponentId">
        <xsl:attribute name="cmd:ComponentId" select="."/>
    </xsl:template>

</xsl:stylesheet>