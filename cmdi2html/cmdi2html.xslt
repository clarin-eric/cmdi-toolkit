<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:cmd="http://www.clarin.eu/cmd/"
    xmlns:fnc="http://127.0.0.1/"
    exclude-result-prefixes="xs"
    version="2.0"
    xpath-default-namespace="http://www.clarin.eu/cmd/">
    <!--    
    <!DOCTYPE html>
    -->

    <xsl:output
        method="html"
        encoding="UTF-8"
        doctype-system="about:legacy-compat"
        indent="yes"
        cdata-section-elements="td"/>
    

    <xsl:template name="component_tree" match="/CMD/Components">
        <xsl:param name="nodeset" as="element()+" select="/CMD/Components"/>

        <ul>
            <xsl:for-each select="$nodeset/element()">
                <xsl:variable name="nchildren" select="count(child::element())"/>

                <li>
                    <code>
                        <xsl:value-of select="concat(local-name(), ' ')"/>
                        <xsl:if test="count(@*) > 0">
                            <div id="attributes">
                                <xsl:for-each select="@*">
                                    <xsl:value-of select="name()"/>="<xsl:value-of select="."/>"
                                </xsl:for-each>
                            </div>
                        </xsl:if>
                    </code>

                    <xsl:choose>
                        <xsl:when test="$nchildren = 0">
                            <br /><br /><sample><xsl:value-of select="self::element()"/></sample>
                        </xsl:when>
                        <xsl:otherwise>
                            <ul>
                                <xsl:call-template name="component_tree">
                                    <xsl:with-param name="nodeset" select="self::element()"/>
                                </xsl:call-template>
                            </ul>
                        </xsl:otherwise>
                    </xsl:choose>
                </li>
            </xsl:for-each>
        </ul>
    </xsl:template>


    <xsl:template match="CMD">
        <html xmlns="http://www.w3.org/1999/xhtml" lang="en" xml:lang="en">
            <meta charset="utf-8"/>
            <head>
                <title>CMDI collection "<xsl:value-of select="./Header/MdCollectionDisplayName" xmlns="cmd"/>"
                </title>
                    <link rel="stylesheet" type="text/css" href="http://catalog.clarin.eu/ds/vlo/css/main.css"/>
             
                <style media="screen" type="text/css">
                    <![CDATA[
                    li
                    {
                        margin: 20px;
                    }
                    
                    code
                    {
                        background-color: rgba(188, 205, 232, 0.8);
                        border: 1px ridge;
                        font-weight: bold;
                        padding: 5px;
                    }
                    
                    sample
                    {
                        background-color: rgba(188, 200, 232, 0.3);
                        border: 1px dotted red;                        
                        margin-top: 10px;
                        padding: 5px;
                        float: none;
                    }
                    
                    #attributes
                    {
                        overflow: hidden;
                        display: inline-block;
                        font-style: italic;
                        font-weight: normal;
                        /* background-color: rgba(100, 201, 234, 0.4); */
                    }
                    
                    address
                    {
                        display: inline-block;
                    }
                    ]]>
                </style>
            </head>
            <body>
                <article>
                    <div class="endgame">
                        <p>
                            <h1>Metadata overview</h1>
                            <table>
                                <caption>Resources</caption>
                                <thead>
                                    <tr>
                                        <th class="attribute">Reference to resource</th>
                                        <th class="attribute">Resource description</th>
                                        <th class="attribute">Resource MIME type</th>
                                        <th class="attribute">Resource Proxy ID</th>
                                    </tr>
                                </thead>
                                <tbody class="attributesTbody">
                                    <xsl:for-each select="Resources/ResourceProxyList/ResourceProxy">
                                        <tr>
                                            <td class="attributeValue">
                                                <xsl:value-of select="ResourceRef"/>
                                            </td>
                                            <td class="attributeValue">
                                                <xsl:value-of select="ResourceType"/>
                                            </td>
                                            <td class="attributeValue">
                                                <xsl:value-of select="ResourceType/@mimetype"/>
                                            </td>
                                            <td class="attributeValue">
                                                <xsl:value-of select="./@id"/>
                                            </td>
                                        </tr>
                                    </xsl:for-each>
                                </tbody>
                            </table>
                        </p>
                    </div>

                    <p>
                        <h1>Journal file proxy list</h1>
                        <xsl:for-each select="JournalFileProxyList"> </xsl:for-each>
                    </p>
                    
                    <p>
                        <h1>Resource relations</h1>
                        <xsl:for-each select="Resources/ResourceRelationList/ResourceRelation"> </xsl:for-each>
                    </p>
                    
                    <p>
                        <h1>CMDI component tree</h1>
                        <xsl:call-template name="component_tree"/>
                    </p>
                    
                    <footer>
                        <p>Created by <address class="author"> <xsl:value-of select="Header/MdCreator"/>
                        </address> on <time datetime="{Header/MdCreationDate}">
                                <xsl:value-of select="normalize-space(Header/MdCreationDate)"
                                /></time>
                            <br />
                            <small>Located at <a href="{Header/MdSelfLink}">
                                    <xsl:value-of select="Header/MdSelfLink"/></a>
                            </small>
                            <br />
                            <small>Belongs to <xsl:value-of select="Header/MdCollectionDisplayName"
                                />
                            </small>
                            <br />
                            <xsl:variable name="resource_URL"
                                select="concat('http://catalog.clarin.eu/ds/ComponentRegistry?item=',Header/MdProfile)"/>
                            <small>Based on <a href="{$resource_URL}"><xsl:value-of select="$resource_URL"/></a>
                            </small>
                        </p>
                    </footer>
                </article>
            </body>
        </html>

    </xsl:template>
</xsl:stylesheet>
