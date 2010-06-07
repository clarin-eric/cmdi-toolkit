<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="2.0" xpath-default-namespace="http://www.mpi.nl/IMDI/Schema/IMDI">

    <xsl:output method="xml" indent="yes" />
    
    <xsl:template match="METATRANSCRIPT">
        <CMD xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
            <Header>
            </Header>           
            <Resources>
                <ResourceProxyList>
                </ResourceProxyList>
                <JournalFileProxyList>
                </JournalFileProxyList>
                <ResourceRelationList>
                </ResourceRelationList>
            </Resources>
            <Components>       
                <xsl:apply-templates select="Corpus" />        
            </Components>
        </CMD>
        
    </xsl:template>
    
    
    <xsl:template match="Corpus">
        <imdi-corpus>
            <Corpus>
                <xsl:apply-templates select="child::Name"/>
                <xsl:apply-templates select="child::Title"/>
                <xsl:if test="exists(child::CorpusLink)">
                    <xsl:for-each select="CorpusLink">
                        <CorpusLink>
                            <!--<xsl:attribute name="ArchiveHandle" select="@ArchiveHandle"/>-->
                            <xsl:attribute name="Name" select="@Name"/>
                            <xsl:value-of select="."/>
                        </CorpusLink>
                    </xsl:for-each>
                </xsl:if>    
                <xsl:if test="exists(child::Description)">
                    <descriptions>
                        <xsl:for-each select="Description">
                            <Description>
                                <xsl:attribute name="LanguageId" select="@LanguageId"/>
                                <xsl:value-of select="."/>
                            </Description>
                        </xsl:for-each>
                    </descriptions>                
                </xsl:if>                    
            </Corpus>
         </imdi-corpus>
    </xsl:template>
    
    <xsl:template match="child::Name">
        <Name>
            <xsl:value-of select="."/>
        </Name>
    </xsl:template>
    
    <xsl:template match="child::Title">
        <Title>
            <xsl:value-of select="."/>
        </Title>
    </xsl:template>
    
     
    
    
</xsl:stylesheet>
