<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="2.0"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
    xmlns:dc="http://purl.org/dc/elements/1.1/"
    xmlns:dcterms="http://purl.org/dc/terms/"
    xmlns:skos="http://www.w3.org/2004/02/skos/core#"
    xmlns:openskos="http://openskos.org/xmlns#"
    exclude-result-prefixes="xs rdf dc dcterms skos openskos">

    <xsl:param name="clavas-uri" select="'https://openskos.meertens.knaw.nl/clavas'"/>
    <xsl:param name="clavas-limit" select="'100000'"/>
    <xsl:param name="clavas-prop" select="'skos:prefLabel'"/>
    <xsl:param name="clavas-lang" select="'en'"/>
    
    <xsl:template match="node() | @*">
        <xsl:copy>
            <xsl:apply-templates select="node() | @*"/>
        </xsl:copy>
    </xsl:template>
    
    <!-- <Vocabulary URI="..."><enumeration/></Vocabulary> pattern is seen as the hint for a closed vocabulary -->
    <xsl:template match="Vocabulary[normalize-space(@URI)!=''][exists(enumeration)]">
        <xsl:variable name="vocab-uri" select="@URI"/>
        <xsl:variable name="vocab-prop" select="if (normalize-space(@ValueProperty)!='') then (normalize-space(@ValueProperty)) else ($clavas-prop)"/>
        <xsl:variable name="vocab-lang" select="if (normalize-space(@ValueLanguage)!='') then (normalize-space(@ValueLanguage)) else ($clavas-lang)"/>
        <xsl:copy>
            <xsl:copy-of select="@*"/>
            <enumeration>
                <xsl:for-each select="doc(concat($clavas-uri,'/api/find-concepts?rows=',$clavas-limit,'&amp;q=inScheme:',replace($vocab-uri,':','\\:')))//rdf:Description[rdf:type/@rdf:resource='http://www.w3.org/2004/02/skos/core#Concept']">
                    <xsl:variable name="entry">
                        <xsl:choose>
                            <xsl:when test="normalize-space(*[name()=$vocab-prop][@xml:lang=$vocab-lang][1])!=''">
                                <xsl:value-of select="normalize-space(*[name()=$vocab-prop][@xml:lang=$vocab-lang][1])"/>
                            </xsl:when>
                            <xsl:when test="normalize-space(*[name()=$vocab-prop][empty(@xml:lang)][1])!=''">
                                <xsl:value-of select="normalize-space(*[name()=$vocab-prop][empty(@xml:lang)][1])"/>
                            </xsl:when>
                            <xsl:when test="normalize-space(*[name()=$vocab-prop][1])!=''">
                                <xsl:value-of select="normalize-space(*[name()=$vocab-prop][1])"/>
                            </xsl:when>
                            <xsl:when test="normalize-space(skos:prefLabel[@xml:lang=$vocab-lang][1])!=''">
                                <xsl:message>WRN: ValueProperty[<xsl:value-of select="$vocab-prop"/>] couldn't be found for entry[<xsl:value-of select="@rdf:about"/>], falling back to skos:prefLabel[<xsl:value-of select="normalize-space(skos:prefLabel[@xml:lang=$vocab-lang][1])"/>]!</xsl:message>
                                <xsl:value-of select="normalize-space(skos:prefLabel[@xml:lang=$vocab-lang][1])"/>
                            </xsl:when>
                            <xsl:when test="normalize-space(skos:prefLabel[empty(@xml:lang)][1])!=''">
                                <xsl:message>WRN: ValueProperty[<xsl:value-of select="$vocab-prop"/>] couldn't be found for entry[<xsl:value-of select="@rdf:about"/>], falling back to skos:prefLabel[<xsl:value-of select="normalize-space(skos:prefLabel[empty(@xml:lang)][1])"/>]!</xsl:message>
                                <xsl:value-of select="normalize-space(skos:prefLabel[empty(@xml:lang)][1])"/>
                            </xsl:when>
                            <xsl:when test="normalize-space(skos:prefLabel[1])!=''">
                                <xsl:message>WRN: ValueProperty[<xsl:value-of select="$vocab-prop"/>] couldn't be found for entry[<xsl:value-of select="@rdf:about"/>], falling back to skos:prefLabel[<xsl:value-of select="normalize-space(skos:prefLabel[1])"/>]!</xsl:message>
                                <xsl:value-of select="normalize-space(skos:prefLabel[1])"/>
                            </xsl:when>
                        </xsl:choose>
                    </xsl:variable>
                    <xsl:choose>
                        <xsl:when test="normalize-space($entry)!=''">
                            <item ConceptLink="{@rdf:about}">
                                <xsl:choose>
                                    <xsl:when test="normalize-space(skos:prefLabel[@xml:lang=$vocab-lang][1])!=''">
                                        <xsl:attribute name="AppInfo" select="normalize-space(skos:prefLabel[@xml:lang=$vocab-lang][1])"/>
                                    </xsl:when>
                                    <xsl:when test="normalize-space(skos:prefLabel[empty(@xml:lang)][1])!=''">
                                        <xsl:attribute name="AppInfo" select="normalize-space(skos:prefLabel[empty(@xml:lang)][1])"/>
                                    </xsl:when>
                                    <xsl:when test="normalize-space(skos:prefLabel[1])!=''">
                                        <xsl:attribute name="AppInfo" select="normalize-space(skos:prefLabel[1])"/>
                                    </xsl:when>
                                </xsl:choose>
                                <xsl:value-of select="$entry"/>
                            </item>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:message>ERR: non empty instance of ValueProperty[<xsl:value-of select="$vocab-prop"/>] couldn't be found for entry[<xsl:value-of select="@rdf:about"/>] and no skos:prefLabel found, skipping it!</xsl:message>
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:for-each>
            </enumeration>
        </xsl:copy>
    </xsl:template>

</xsl:stylesheet>
