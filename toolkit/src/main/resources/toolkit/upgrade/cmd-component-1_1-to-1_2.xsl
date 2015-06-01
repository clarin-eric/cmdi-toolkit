<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:cue="http://www.clarin.eu/cmdi/cues/display/1.0"
    exclude-result-prefixes="xs"
    version="2.0">

    <xsl:param name="cmd-toolkit" select="'../../../../../main/resources/toolkit'"/>    
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
        <ComponentSpec>
            <xsl:apply-templates select="@*|node()"/>
        </ComponentSpec>
    </xsl:template>

    <xsl:template match="CMD_Component" priority="1">
        <Component>
            <xsl:apply-templates select="@*|node()"/>
        </Component>
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
    
    <!-- turn @Documentation into <Documentation/> -->
    <xsl:template match="@Documentation" priority="1">
        <Documentation>
            <xsl:value-of select="."/>
        </Documentation>
    </xsl:template>

    <!-- add Vocabulary level -->
    <xsl:template match="enumeration" priority="1">
        <Vocabulary>
            <enumeration>
                <xsl:apply-templates select="@*|node()"/>
            </enumeration>
        </Vocabulary>
    </xsl:template>
    
    <!-- turn Attribute child elements into attributes -->
    <xsl:template match="Attribute" priority="1">
        <Attribute name="{Name}">
            <xsl:if test="normalize-space(Type)!=''">
                <xsl:attribute name="ValueScheme" select="Type"/>
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