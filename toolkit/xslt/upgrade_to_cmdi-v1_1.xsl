<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0"
    xmlns="http://www.clarin.eu/cmd/"
    xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
    
    <xsl:variable name="CMDVersion" select="'1.1'"/>
    
    <!-- identity template for attributes and text nodes -->
    <xsl:template match="@*|text()">
        <xsl:copy/>
    </xsl:template>
    
    <!-- add the default CMD namespace and the new version attribute to the root element -->
    <xsl:template match="CMD">
        <CMD xmlns="http://www.clarin.eu/cmd/" CMDVersion="{$CMDVersion}">
            <xsl:apply-templates select="@*|node()"/>
        </CMD>
    </xsl:template>
    
    <!-- rewrite @xsi:npNamespaceSchemaLocation -->
    <xsl:template match="CMD/@xsi:noNamespaceSchemaLocation">
        <xsl:attribute name="xsi:schemaLocation">
            <xsl:text>http://www.clarin.eu/cmd/</xsl:text>
            <xsl:text> </xsl:text>
            <xsl:value-of select="."/>
        </xsl:attribute>
    </xsl:template>
    
    <!-- add the default CMD namespace to all elements -->
    <xsl:template match="*">
        <xsl:element namespace="http://www.clarin.eu/cmd/" name="{name()}">
            <xsl:apply-templates select="@*|node()"/>
        </xsl:element>
    </xsl:template>
    
</xsl:stylesheet>