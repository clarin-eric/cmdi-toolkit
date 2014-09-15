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
    
    <!-- Create or own xsi:schemaLocation -->
    <xsl:template match="@xsi:schemaLocation"/>
    
    <xsl:template match="@xsi:noNamespaceSchemaLocation"/>
    
    <xsl:template match="cmd:CMD">
        <xsl:copy>
            <xsl:apply-templates select="@* except (@xsi:schemaLocation|@xsi:noNamespaceSchemaLocation)"/>
            <xsl:attribute name="xsi:schemaLocation">
                <xsl:text>http://www.clarin.eu/cmd/ </xsl:text>
                <xsl:value-of select="$cmd-envelop-xsd"/>
                <xsl:text> </xsl:text>
                <xsl:value-of select="$profile"/>
                <xsl:text> </xsl:text>
                <xsl:value-of select="$cmd-profile-xsd"/>
            </xsl:attribute>
            <xsl:apply-templates/>
        </xsl:copy>
    </xsl:template>
    
    <!-- Make sure Header contains MdProfile -->

</xsl:stylesheet>