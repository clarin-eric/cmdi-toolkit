<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:cue="http://www.clarin.eu/cmd/cues/1"
    exclude-result-prefixes="xs"
    version="2.0">

    <xsl:param name="cmd-toolkit" select="'https://infra.clarin.eu/CMDI/1.x'"/>    
    <xsl:param name="cmd-component-xsd" select="concat($cmd-toolkit,'/xsd/cmd-component.xsd')"/>
    <xsl:param name="cmd-component-status" select="'production'"/>
    
    <!-- identity copy -->
    <xsl:template match="@*">
        <xsl:copy/>
    </xsl:template>
    
    <xsl:template match="node()">
        <xsl:copy>
            <xsl:apply-templates select="@* except @Documentation"/>
            <xsl:apply-templates select="@Documentation"/>
            <xsl:apply-templates select="node()"/>
        </xsl:copy>
    </xsl:template>

    <!-- refer to cmd-component.xsd -->
    <xsl:template match="@xsi:schemaLocation" priority="1">
        <xsl:attribute name="xsi:noNamespaceSchemaLocation" select="$cmd-component-xsd"/>
    </xsl:template>

    <!-- get rid of CMD_ prefix -->
    <xsl:template match="CMD_ComponentSpec" priority="1">
        <ComponentSpec CMDVersion="1.2" CMDOriginalVersion="1.1">
            <xsl:apply-templates select="@*|node()"/>
        </ComponentSpec>
    </xsl:template>

    <xsl:template match="CMD_Component" priority="1">
        <Component>
            <xsl:apply-templates select="@*|node()"/>
        </Component>
    </xsl:template>
    
    <xsl:template match="CMD_Component/@filename">
        <!-- Ignore -->
    </xsl:template>
    
    <xsl:template match="CMD_ComponentSpec/CMD_Component/@CardinalityMin">
        <xsl:if test=".!='1'">
            <xsl:message>WRN: the root component can only have a minimum cardinality of one (not <xsl:value-of select="."/>)!</xsl:message>
        </xsl:if>
        <xsl:attribute name="CardinalityMin" select="1"/>
    </xsl:template>
    
    <xsl:template match="CMD_ComponentSpec/CMD_Component/@CardinalityMax">
        <xsl:if test=".!='1'">
            <xsl:message>WRN: the root component can only have a maximum cardinality of one (not <xsl:value-of select="."/>)!</xsl:message>
        </xsl:if>
        <xsl:attribute name="CardinalityMax" select="1"/>
    </xsl:template>

    <xsl:template match="CMD_Element" priority="1">
        <Element>
            <xsl:apply-templates select="@* except @Documentation"/>
            <xsl:apply-templates select="@Documentation"/>
            <xsl:apply-templates select="node()"/>
        </Element>
    </xsl:template>
    
    <!-- add Status -->
    <xsl:template match="Header" priority="1">
        <xsl:copy>
            <xsl:apply-templates select="@*|node()"/>
            <Status>
                <xsl:value-of select="$cmd-component-status"/>
            </Status>
        </xsl:copy>
    </xsl:template>
    
    <!-- turn @ComponentId into @ComponentRef -->
    <xsl:template match="@ComponentId" priority="1">
        <xsl:attribute name="ComponentRef" select="."/>
    </xsl:template>

    <!-- turn @Documentation into <Documentation/> -->
    <xsl:template match="@Documentation" priority="1">
        <Documentation>
            <xsl:value-of select="."/>
        </Documentation>
    </xsl:template>
    
    <!-- check @ValueScheme -->
    <xsl:template match="@ValueScheme" priority="1">
        <xsl:choose>
            <xsl:when test="exists(../ValueScheme) and current()='string'">
                <!-- there is a <ValueScheme> and the @ValueScheme='string', silently ignore the @ValueScheme -->
            </xsl:when>
            <xsl:when test="exists(../ValueScheme) and current()!='string'">
                <xsl:message>WRN: <xsl:value-of select="/CMD_ComponentSpec/Header/ID"/>: element with both a ValueScheme and a non-string @ValueScheme(<xsl:value-of select="."/>)! The @ValueScheme is ignored!</xsl:message>
            </xsl:when>
            <xsl:otherwise>
                <xsl:attribute name="ValueScheme" select="."/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <!-- add Vocabulary level -->
    <xsl:template match="enumeration" priority="1">
        <Vocabulary>
            <enumeration>
                <xsl:apply-templates select="@*"/>
                <xsl:if test="exists(appinfo[normalize-space()!=''])">
                    <appinfo>
                        <xsl:value-of select="(appinfo[normalize-space()!=''])[1]"/>
                    </appinfo>
                </xsl:if>
                <xsl:for-each-group select="item" group-by="string()">
                    <xsl:choose>
                        <xsl:when test="count(current-group()) gt 1">
                            <xsl:for-each-group select="current-group()" group-by="string-join((normalize-space(@ConceptLink),normalize-space(@AppInfo)),'-')">
                                <xsl:choose>
                                    <xsl:when test="last()=1">
                                        <xsl:message>WRN: <xsl:value-of select="/CMD_ComponentSpec/Header/ID"/>: multiple enumeration items for '<xsl:value-of select="current-group()[1]/string()"/>', but they can and are merged into one!</xsl:message>
                                        <xsl:apply-templates select="current-group()[1]"/>
                                    </xsl:when>
                                    <xsl:otherwise>
                                        <xsl:message>ERR: <xsl:value-of select="/CMD_ComponentSpec/Header/ID"/>: multiple enumeration items for '<xsl:value-of select="current-group()[1]/string()"/>'!</xsl:message>
                                        <xsl:apply-templates select="current-group()[1]"/>
                                    </xsl:otherwise>
                                </xsl:choose>
                            </xsl:for-each-group>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:apply-templates select="current-group()[1]"/>
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:for-each-group>
            </enumeration>
        </Vocabulary>
    </xsl:template>
    
    <!-- turn Attribute child elements into attributes -->
    <xsl:template match="Attribute" priority="1">
        <Attribute name="{Name}">
            <xsl:if test="normalize-space(Type)!=''">
                <xsl:choose>
                    <xsl:when test="exists(ValueScheme) and normalize-space(Type)='string'"/>
                    <xsl:when test="exists(ValueScheme) and normalize-space(Type)!='string'">
                        <xsl:message>WRN: <xsl:value-of select="/CMD_ComponentSpec/Header/ID"/>: attribute with both a ValueScheme and a non-string Type(<xsl:value-of select="Type"/>)! The Type is ignored!</xsl:message>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:attribute name="ValueScheme" select="Type"/>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:if>
            <xsl:if test="normalize-space(ConceptLink)!=''">
                <xsl:attribute name="ConceptLink" select="ConceptLink"/>
            </xsl:if>
            <xsl:apply-templates select="* except Name except Type except ConceptLink"/>
        </Attribute>
    </xsl:template>
    
    <!-- put DisplayPriority in the cues namespace -->
    <xsl:template match="@DisplayPriority" priority="1">
        <xsl:attribute name="cue:DisplayPriority">
            <xsl:value-of select="."/>
        </xsl:attribute>
    </xsl:template>
    
</xsl:stylesheet>