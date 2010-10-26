<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="2.0"
    xmlns:dc="http://purl.org/dc/elements/1.1/"
    xmlns:oai_dc="http://www.openarchives.org/OAI/2.0/oai_dc/"
    xmlns:defns="http://www.openarchives.org/OAI/2.0/"
    xmlns:olac="http://www.language-archives.org/OLAC/1.0/"
    xsi:schemaLocation="    http://purl.org/dc/elements/1.1/    http://www.language-archives.org/OLAC/1.0/dc.xsd    http://purl.org/dc/terms/    http://www.language-archives.org/OLAC/1.0/dcterms.xsd    http://www.language-archives.org/OLAC/1.0/    http://www.language-archives.org/OLAC/1.0/olac.xsd    http://www.language-archives.org/OLAC/1.0/third-party/software.xsd ">

    <!-- run on ubtunu with: saxonb-xslt -ext:on -it main ~/svn/clarin/metadata/trunk/toolkit/xslt/olac2cmdi.xsl  -->

    <xsl:output method="xml" version="1.0" encoding="UTF-8" indent="yes"/>

    <!-- identity copy -->
<!--    <xsl:template match="@*|node()">
        <xsl:copy>
            <xsl:apply-templates select="@*|node()"/>
        </xsl:copy>
    </xsl:template>
-->
    
    <xsl:template match="/">
        <CMD
            xsi:schemaLocation="http://www.clarin.eu/cmd http://catalog.clarin.eu/ds/ComponentRegistry/rest/registry/profiles/clarin.eu:cr1:p_1271859438236/xsd">
            <Header>
                <MdCreator>olac2cmdi.xsl</MdCreator>
                <MdCreationDate>
                    <xsl:variable name="date">
                        <xsl:value-of select="//defns:datestamp"/>
                    </xsl:variable>
                    <xsl:choose>
                        <xsl:when test="contains($date,'T')">
                            <xsl:value-of select="substring-before($date,'T')"/>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:value-of select="$date"/>
                        </xsl:otherwise>
                    </xsl:choose>
                </MdCreationDate>
                <MdSelfLink>
                    <xsl:value-of select="//defns:identifier"/>
                </MdSelfLink>
                <MdProfile>clarin.eu:cr1:p_1271859438236</MdProfile>
            </Header>
            <Resources>
                <ResourceProxyList/>
                <JournalFileProxyList/>
                <ResourceRelationList/>
            </Resources>
            <Components>
                <olac>

                    <xsl:apply-templates select="//dc:contributor"/>
                    <xsl:apply-templates select="//dc:coverage"/>
                    <xsl:apply-templates select="//dc:creator"/>
                    <xsl:apply-templates select="//dc:date"/>
                    <xsl:apply-templates select="//dc:description"/>
                    <xsl:apply-templates select="//dc:format"/>
                    <xsl:apply-templates select="//dc:identifier"/>
                    <xsl:apply-templates select="//dc:language"/>
                    <xsl:apply-templates select="//dc:publisher"/>
                    <xsl:apply-templates select="//dc:relation"/>
                    <xsl:apply-templates select="//dc:rights"/>
                    <xsl:apply-templates select="//dc:source"/>
                    <xsl:apply-templates select="//dc:subject"/>
                    <xsl:apply-templates select="//dc:title"/>
                    <xsl:apply-templates select="//dc:type"/>

                </olac>
            </Components>
        </CMD>
    </xsl:template>

    <xsl:template match="dc:contributor">
        <olac-contributor>
            <xsl:if test="@xsi:type='olac:role'">
                <xsl:attribute name="olac-role">
                    <xsl:value-of select="@olac:code"/>
                </xsl:attribute>
            </xsl:if>
            <xsl:value-of select="."/>
        </olac-contributor>
    </xsl:template>


    <xsl:template match="dc:creator">
        <olac-creator>
            <xsl:value-of select="."/>
        </olac-creator>
    </xsl:template>

    <xsl:template match="dc:date">
        <olac-date>
            <xsl:value-of select="."/>
        </olac-date>
    </xsl:template>

    <xsl:template match="dc:description">
        <olac-description>
           <xsl:apply-templates select="./@xml:lang"/>            
            <xsl:value-of select="."/>
        </olac-description>
    </xsl:template>

    <xsl:template match="dc:format">
        <olac-format>
            <xsl:value-of select="."/>
        </olac-format>
    </xsl:template>

    <xsl:template match="dc:identifier">
        <olac-identifier>
            <xsl:value-of select="."/>
        </olac-identifier>
    </xsl:template>

    <xsl:template match="dc:language">
        <olac-language>
            <xsl:value-of select="."/>
        </olac-language>
    </xsl:template>

    <xsl:template match="dc:language[@xsi:type='olac:language']" priority="3">
        <olac-language>
            <xsl:attribute name="olac-language">
                <xsl:value-of select="@olac:code"/>
            </xsl:attribute>
        </olac-language>
    </xsl:template>


    <xsl:template match="dc:publisher">
        <olac-publisher>
            <xsl:value-of select="."/>
        </olac-publisher>
    </xsl:template>

    <xsl:template match="dc:relation">
        <olac-relation>
            <xsl:value-of select="."/>
        </olac-relation>
    </xsl:template>


    <xsl:template match="dc:rights">
        <olac-rights>
            <xsl:value-of select="."/>
        </olac-rights>
    </xsl:template>


    <xsl:template match="//dc:subject[@xsi:type='olac:linguistic-field']" priority="3">
        <olac-subject>
            <xsl:attribute name="olac-linguistic-field">
                <xsl:value-of select="@olac:code"/>
            </xsl:attribute>
        </olac-subject>
    </xsl:template>

    <xsl:template match="//dc:subject[@xsi:type='olac:discourse-type']" priority="3">
        <olac-subject>
            <xsl:attribute name="olac-discourse-type">
                <xsl:value-of select="@olac:code"/>
            </xsl:attribute>
        </olac-subject>
    </xsl:template>


    <xsl:template match="//dc:subject" priority="1">
        <olac-subject>
            <xsl:apply-templates select="./@xml:lang"/>
            <xsl:value-of select="."/>
        </olac-subject>
    </xsl:template>


    <xsl:template match="//dc:title">
        <title>
            <xsl:apply-templates select="./@xml:lang"/>
            <xsl:value-of select="."/>
        </title>
    </xsl:template>


    <xsl:template match="//dc:type[@xsi:type='olac:discourse-type']" priority="2">
        <type>
            <xsl:attribute name="olac-discourse-type">
                <xsl:value-of select="@olac:code"/>
            </xsl:attribute>
        </type>
    </xsl:template>


    <xsl:template match="//dc:type[@xsi:type='olac:linguistic-type']" priority="2">
        <type>
            <xsl:attribute name="olac-linguistic-type">
                <xsl:value-of select="@olac:code"/>
            </xsl:attribute>
        </type>
    </xsl:template>


    <xsl:template match="//dc:type" priority="1">
        <type>
            <xsl:value-of select="."/>
        </type>
    </xsl:template>

    <xsl:template match="@xml:lang">
        <xsl:attribute name="xml:lang">
            <xsl:value-of select="."/>
        </xsl:attribute>
    </xsl:template>


    <xsl:template name="main">
        <xsl:for-each
            select="collection('file:////home/dietuyt/olac?select=*.xml;recurse=yes;on-error=ignore')">
            <xsl:result-document href="{document-uri(.)}.cmdi">
                <xsl:apply-templates select="."/>
            </xsl:result-document>
        </xsl:for-each>
    </xsl:template>


</xsl:stylesheet>
