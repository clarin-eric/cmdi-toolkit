<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="2.0" xmlns:dc="http://purl.org/dc/elements/1.1/"  xmlns:oai_dc="http://www.openarchives.org/OAI/2.0/oai_dc/">
    
    <xsl:output method="xml" version="1.0" encoding="UTF-8" indent="yes"/>

    <!-- identity copy -->
    <xsl:template match="@*|node()">
        <xsl:copy>
            <xsl:apply-templates select="@*|node()"/>
        </xsl:copy>
    </xsl:template>


    <xsl:template match="/">
        <CMD xsi:schemaLocation="http://www.clarin.eu/cmd http://catalog.clarin.eu/ds/ComponentRegistry/rest/registry/profiles/clarin.eu:cr1:p_1271859438236/xsd">
        <Header><MdProfile>clarin.eu:cr1:p_1271859438236</MdProfile></Header>
        <Resources>
            <ResourceProxyList></ResourceProxyList>
            <JournalFileProxyList></JournalFileProxyList>
            <ResourceRelationList></ResourceRelationList>
        </Resources>
        <Components>
            <olac>
                
                <xsl:for-each select="//dc:contributor">
                    <olac-contributor><xsl:apply-templates select="."/></olac-contributor>    
                </xsl:for-each>
                
                <xsl:for-each select="//dc:creator">
                    <olac-creator><xsl:apply-templates select="."/></olac-creator>    
                </xsl:for-each>
              
              
                <xsl:for-each select="//dc:date">
                    <olac-date><xsl:apply-templates select="."/></olac-date>    
                </xsl:for-each>
                
                
                <xsl:for-each select="//dc:description">
                    <olac-description><xsl:apply-templates select="."/></olac-description>    
                </xsl:for-each>
                
                <xsl:for-each select="//dc:format">
                    <olac-format><xsl:apply-templates select="."/></olac-format>    
                </xsl:for-each>
                
                
                <xsl:for-each select="//dc:identifier">
                    <olac-identifier><xsl:apply-templates select="."/></olac-identifier>    
                </xsl:for-each>
                
                <xsl:for-each select="//dc:language">
                    <olac-language><xsl:apply-templates select="."/></olac-language>    
                </xsl:for-each>
                
                <xsl:for-each select="//dc:publisher">
                    <olac-publisher><xsl:apply-templates select="."/></olac-publisher>    
                </xsl:for-each>
                
                <xsl:for-each select="//dc:relation">
                    <olac-relation><xsl:apply-templates select="."/></olac-relation>    
                </xsl:for-each>
                
                <xsl:for-each select="//dc:rights">
                    <olac-rights><xsl:apply-templates select="."/></olac-rights>    
                </xsl:for-each>
                
                <xsl:for-each select="//dc:source">
                    <olac-source><xsl:apply-templates select="."/></olac-source>    
                </xsl:for-each>
                
                <xsl:for-each select="//dc:subject">
                    <olac-subject><xsl:apply-templates select="."/></olac-subject>    
                </xsl:for-each>
                                
                <xsl:for-each select="//dc:title">
                    <title><xsl:apply-templates select="."/></title>    
                </xsl:for-each>
                
                <xsl:for-each select="//dc:type">
                    <type><xsl:apply-templates select="."/></type>    
                </xsl:for-each>
    
            </olac>
        </Components>
        </CMD>
    </xsl:template>
    
    
    <xsl:template match="dc:*">
        <xsl:value-of select="."/>
    </xsl:template>


    <xsl:template name="main">
        <xsl:for-each select="collection('file:////home/dietuyt/olac?select=*.xml;recurse=yes;on-error=ignore')">
            <xsl:result-document href="{document-uri(.)}.cmdi">
                <xsl:apply-templates select="."/>
            </xsl:result-document>
        </xsl:for-each>
    </xsl:template> 
    

</xsl:stylesheet>
