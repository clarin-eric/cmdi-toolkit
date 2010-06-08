<?xml version="1.0" encoding="UTF-8"?>

<!-- 
    $Rev: 484 $
    $Date$
-->

<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="2.0"
    xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:dcr="http://www.isocat.org"
    xmlns:ann="http://www.clarin.eu">
    <xsl:strip-space elements="*"/>
    <xsl:output method="xml" version="1.0" encoding="UTF-8" indent="yes"/>

    <xsl:template match="/xs:schema">
        <xs:schema>
            <!-- Remove double entries for named simpleType and complexType definitions at the begin of the XSD.  -->
            <xsl:for-each-group select="./xs:simpleType" group-by="@name">
                <!-- only take the first item -->
                <xsl:copy-of select="current-group( )[1]"/>
            </xsl:for-each-group>

            <xsl:for-each-group select="./xs:complexType" group-by="@name">
                <!-- only take the first item -->
                <xsl:copy-of select="current-group( )[1]"/>
            </xsl:for-each-group>

            <xsl:apply-templates select="xs:element"/>

        </xs:schema>
    </xsl:template>


    <!-- identity copy -->
    <xsl:template match="@*|node()">
        <xsl:copy>
            <xsl:apply-templates select="@*|node()"/>
        </xsl:copy>
    </xsl:template>


</xsl:stylesheet>
