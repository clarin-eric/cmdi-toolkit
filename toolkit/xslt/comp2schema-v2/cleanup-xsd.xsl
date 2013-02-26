<?xml version="1.0" encoding="UTF-8"?>

<!-- 
    $Rev$
    $Date$
-->

<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="2.0"
    xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:dcr="http://www.isocat.org/ns/dcr"
    xmlns:ann="http://www.clarin.eu">
    <xsl:strip-space elements="*"/>
    <xsl:output method="xml" version="1.0" encoding="UTF-8" indent="no" />

    <xsl:template match="/xs:schema" mode="clean">
        <xs:schema xmlns:cmd="http://www.clarin.eu/cmd/">
            <xsl:copy-of select="@*"/>
	    <!-- Keep the annotation with header information -->
            <xsl:copy-of select="xs:annotation" />
            <xsl:apply-templates select="xs:import" mode="clean"/>
            <!-- Remove double entries for named simpleType and complexType definitions at the begin of the XSD.  -->
            <xsl:for-each-group select="./xs:simpleType" group-by="@name">
                <!-- only take the first item -->
                <xsl:copy-of select="current-group( )[1]"/>
            </xsl:for-each-group>

            <xsl:for-each-group select="./xs:complexType" group-by="@name">
                <!-- only take the first item -->
                <xsl:copy-of select="current-group( )[1]"/>
            </xsl:for-each-group>

            <xsl:apply-templates select="xs:element" mode="clean"/>
        </xs:schema>
    </xsl:template>


    <!-- identity copy -->
    <xsl:template match="@*|node()" mode="clean">
        <xsl:copy>
            <xsl:apply-templates select="@*|node()" mode="clean"/>
        </xsl:copy>
    </xsl:template>


</xsl:stylesheet>
