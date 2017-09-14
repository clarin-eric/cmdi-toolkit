<sch:schema xmlns:sch="http://purl.oclc.org/dsdl/schematron" queryBinding="xslt2">
    <sch:ns uri="http://www.clarin.eu/cmd/1" prefix="cmd"/>
    <sch:ns uri="http://www.w3.org/2001/XMLSchema-instance" prefix="xsi"/>
<!--
    <pattern>
        <title>Test cmd:MdProfile</title>
        <rule role="warning" context="cmd:Header">
            <assert test="string-length(cmd:MdProfile/text()) &gt; 0">
                [CMDI Best Practices] A CMDI instance should contain a non-empty &lt;cmd:MdProfile&gt; element in &lt;cmd:Header&gt;.
            </assert>
        </rule>   
    </pattern>

    <pattern>
        <title>Test cmd:MdSelfLink</title>
        <rule  role="warning" context="cmd:Header">
            <assert test="string-length(cmd:MdSelfLink/text()) &gt; 0">
                [CMDI Best Practices] A CMDI instance should contain a non-empty &lt;cmd:MdSelfLink&gt; element in &lt;cmd:Header&gt;.
            </assert>
        </rule>   
    </pattern>

    <!-\- Does the schema reside in the Component Registry? -\->
    <pattern>
        <title>Test xsi:schemaLocation</title>
        <rule role="warning" context="/cmd:CMD">
            <assert test="matches(@xsi:schemaLocation,'http(s)?://catalog.clarin.eu/ds/ComponentRegistry/rest/')">
                [CMDI Best Practice] /cmd:CMD/@xsi:schemaLocation doesn't refer to a schema from the Component Registry! [Actual value was [<value-of select="@xsi:schemaLocation"/>]
            </assert>
        </rule>
    </pattern>
    
    <!-\- Is there at least one ResourceProxy? -\->
    <pattern>
        <title>Test for ResourceProxies</title>
        <rule role="warning" context="/cmd:CMD/cmd:Resources/cmd:ResourceProxyList">
            <assert test="count(cmd:ResourceProxy) ge 1">
                [CMDI Best Practices] There are no ResourceProxies! Does the metadata not describe any (digital) resources?
            </assert>
        </rule>
    </pattern>
    
    <!-\- Can we determine the profile used? -\->
    <pattern>
        <title>Test for known profile</title>
        <rule role="warning" context="/cmd:CMD">
            <assert test="matches(@xsi:schemaLocation,'clarin.eu:cr[0-9]+:p_[0-9]+') or matches(cmd:Header/cmd:MdProfile,'clarin.eu:cr[0-9]+:p_[0-9]+')">
                [CMDI Best Practice] the CMD profile of this record can't be found in the /cmd:CMD/@xsi:schemaLocation or /cmd:CMD/cmd:Header/cmd:MdProfile. The profile should be known for the record to be processed properly in the CLARIN joint metadata domain!
            </assert>
        </rule>
    </pattern>
    
    <!-\- Do the MdProfile and the @xsi:schemaLocation refer to the same profile? -\->
    <pattern>
        <title>Test if MdProfile and @xsi:schemaLocation are in sync</title>
        <rule role="warning" context="/cmd:CMD[matches(@xsi:schemaLocation,'clarin.eu:cr[0-9]+:p_[0-9]+') and matches(cmd:Header/cmd:MdProfile,'clarin.eu:cr[0-9]+:p_[0-9]+')]">
            <assert test="replace(@xsi:schemaLocation,'(clarin.eu:cr[0-9]+:p_[0-9]+)','$1') = replace(cmd:Header/cmd:MdProfile,'(clarin.eu:cr[0-9]+:p_[0-9]+)','$1')">
                [CMDI Best Practice] The CMD profile referenced in the @xsi:schemaLocation is different than the one specified in /cmd:CMD/cmd:Header/cmd:MdProfile. They should be the same!
            </assert>
        </rule>
    </pattern>
    
    <!-\- Is the CMD namespace bound to a schema? -\->
    <pattern>
        <title>Test for CMD namespace schema binding</title>
        <rule role="warning" context="/cmd:CMD">
            <assert test="matches(@xsi:schemaLocation,'http://www.clarin.eu/cmd/1 ')">
                [CMDI Best Practice] is the CMD 1.2 namespace bound to the envelop schema?
            </assert>
        </rule>
    </pattern>
    
    <!-\- Is the CMD profile namespace bound to a schema? -\->
    <pattern>
        <title>Test for CMD profile namespace schema binding</title>
        <rule role="warning" context="/cmd:CMD">
            <assert test="matches(@xsi:schemaLocation,'http://www.clarin.eu/cmd/1/profiles/')">
                [CMDI Best Practice] is the CMD 1.2 profile namespace bound to the profile schema?
            </assert>
        </rule>
    </pattern>
    
    <!-\- if the following rules trigger XSD validation will (have) fail(ed)! -\->
    
    <!-\- Is the cmd:CMD root there? -\->
    <pattern>
        <title>Test for cmd:CMD root</title>
        <rule role="warning" context="/">
            <assert test="exists(cmd:CMD)">
                [CMDI violation] is this really a CMD record? Is the namespace properly declared, e.g., including ending slash?
            </assert>
        </rule>
    </pattern>    
-->
    
    <!-- CE-2017-1076 - CLARIN's CMDI Best Practices Guide -->
    
    <sch:let name="BPG" value="'CE-2017-1076'"/>
    
    <!-- TODO: C6 - need to distinguis between empty component and element! (done once in 1.1 to 1.2 upgrade XSLT, can it be reused in Schematron?) -->
    
    <sch:pattern id="X1">
        <sch:title>X1: Include a reference to the profile XSD generated by the Component Registry</sch:title>
        <sch:rule role="warning" context="/cmd:CMD">
            <sch:assert test="matches(@xsi:schemaLocation,'http(s)?://catalog.clarin.eu/ds/ComponentRegistry/rest/')">[<sch:value-of select="$BPG"/>][X1] Each CMD record should refer to an XSD in the Component Registry!</sch:assert>
        </sch:rule>
    </sch:pattern>
    
    <sch:pattern id="X2">
        <sch:title>X2: Use common namespace prefixes</sch:title>
        <sch:rule role="warning" context="/cmd:CMD">
            <sch:assert test="starts-with(name(),'cmd:')">[<sch:value-of select="$BPG"/>][X2] Use the cmd: prefix for the CMD envelop!</sch:assert>
            <sch:assert test="starts-with(name(@xsi:schemaLocation),'xsi:')">[<sch:value-of select="$BPG"/>][X2] Use the xsi: prefix for the schema location attribute!</sch:assert>
        </sch:rule>
        <sch:rule role="warning" context="/cmd:CMD/cmd:Components/*">
            <sch:assert test="starts-with(name(),'cmdp:')">[<sch:value-of select="$BPG"/>][X2] Use the cmdp: prefix for the CMD payload!</sch:assert>
        </sch:rule>
    </sch:pattern>
    
    <sch:pattern id="E1">
        <sch:title>E1: Include a MdSelfLink</sch:title>
        <sch:rule context="cmd:Header" role="warning">
            <sch:assert test="normalize-space(cmd:MdSelfLink)!=''">[<sch:value-of select="$BPG"/>][E1] Each CMD record should have a MdSelfLink!</sch:assert>
        </sch:rule>
    </sch:pattern>
    
    <sch:pattern id="E2">
        <sch:title>E2: The MdSelfLink should be a Persistent Identifier (PID)</sch:title>
        <sch:rule context="cmd:Header" role="warning">
            <sch:assert test="matches(normalize-space(cmd:MdSelfLink),'^(http(s)?://hdl.handle.net/|hdl:).*$')">[<sch:value-of select="$BPG"/>][E2] The MdSelfLink should be a Persistent Identifier (PID)!</sch:assert>
        </sch:rule>
    </sch:pattern>
        
    <sch:pattern id="E3">
        <sch:title>E3: Include a MdCollectionDisplayName</sch:title>
        <sch:rule context="cmd:Header" role="warning">
            <sch:assert test="normalize-space(cmd:MdCollectionDisplayName)!=''">[<sch:value-of select="$BPG"/>][E3] Each CMD record should have a MdCollectionDisplayName!</sch:assert>
        </sch:rule>
    </sch:pattern>
    
    <sch:pattern id="E4">
        <sch:title>E4: Include a matching MdProfile</sch:title>
        <sch:rule role="warning" context="/cmd:CMD">
            <sch:assert test="matches(cmd:Header/cmd:MdProfile,'^clarin.eu:cr[0-9]+:p_[0-9]+$')">[<sch:value-of select="$BPG"/>][E4] MdProfile should contain a CLARIN Component Registry profile identifier!</sch:assert>
            <sch:assert test="replace(@xsi:schemaLocation,'^.*(clarin.eu:cr[0-9]+:p_[0-9]+).*$','$1') = replace(cmd:Header/cmd:MdProfile,'^.*(clarin.eu:cr[0-9]+:p_[0-9]+).*$','$1')">[<sch:value-of select="$BPG"/>][E4] MdProfile and @xsi:schemaLocation should agree on the profile used!</sch:assert>
        </sch:rule>
    </sch:pattern>

    <sch:pattern id="E5">
        <sch:title>E5: There should be at least one resource proxy</sch:title>
        <sch:rule role="warning" context="/cmd:CMD/cmd:Resources/cmd:ResourceProxyList">
            <sch:assert test="count(cmd:ResourceProxy) ge 1">[<sch:value-of select="$BPG"/>][E5] A CMD record should have at least one Resource Proxy!</sch:assert>
        </sch:rule>
    </sch:pattern>
    
    <sch:pattern id="E6">
        <sch:title>E6: The URI of a resource proxy should be absolute and resolvable</sch:title>
        <sch:rule role="warning" context="cmd:ResourceProxy">
            <sch:assert test="normalize-space(cmd:ResourceRef)!=''">[<sch:value-of select="$BPG"/>][E6] A Resource Proxy should have a reference!</sch:assert>
            <sch:assert test="resolve-uri(normalize-space(cmd:ResourceRef),base-uri())=normalize-space(cmd:ResourceRef)">[<sch:value-of select="$BPG"/>][E6] The reference of a Resource Proxy should be absolute!</sch:assert>
        </sch:rule>
        <!-- TODO: check if resolvable, also an option of the CMDI validator -->
    </sch:pattern>
    
    <sch:pattern id="E7">
        <sch:title>E7: "Metadata" type resource proxies should refer to a CMD record</sch:title>
        <sch:rule role="warning" context="cmd:ResourceProxy[cmd:ResourceType='Metadata']">
            <sch:assert test="cmd:ResourceType/@mimetype='application/x-cmdi+xml'">[<sch:value-of select="$BPG"/>][E7] A metadata Resource Proxy should point to another CMD record (indicated by the CMDI MIME/media type)!</sch:assert>
        </sch:rule>
        <!-- TODO: fetch the record and sniff if its CMDI -->
    </sch:pattern>

    <sch:pattern id="E8">
        <sch:title>E8: "Metadata" type resource proxies should use PIDs</sch:title>
        <sch:rule context="cmd:ResourceProxy[cmd:ResourceType='Metadata']" role="warning">
            <sch:assert test="matches(normalize-space(cmd:ResourceRef),'^(http(s)?://hdl.handle.net/|hdl:).*$')">[<sch:value-of select="$BPG"/>][E8] The reference of a metadata Resource Proxy should be a Persistent Identifier (PID)!</sch:assert>
        </sch:rule>
    </sch:pattern>
    
    <sch:pattern id="E9">
        <sch:title>E9: Specify the MIME type of a resource</sch:title>
        <sch:rule role="warning" context="cmd:ResourceProxy[cmd:ResourceType='Resource']">
            <sch:assert test="normalize-space(cmd:ResourceType/@mimetype)!=''">[<sch:value-of select="$BPG"/>][E9] The MIME/media type of resource should be specified!</sch:assert>
        </sch:rule>
    </sch:pattern>
    
    <sch:pattern id="E10">
        <sch:title>E10: "Resource" type resource proxies should use PIDs</sch:title>
        <sch:rule context="cmd:ResourceProxy[cmd:ResourceType='Resource']" role="warning">
            <sch:assert test="matches(normalize-space(cmd:ResourceRef),'^(http(s)?://hdl.handle.net/|hdl:).*$')">[<sch:value-of select="$BPG"/>][E10] The reference of a resource should be a Persistent Identifier (PID)!</sch:assert>
        </sch:rule>
    </sch:pattern>
    
    <sch:pattern id="E11">
        <sch:title>E11: Provide no more than one LandingPage</sch:title>
        <sch:rule role="warning" context="/cmd:CMD/cmd:Resources/cmd:ResourceProxyList">
            <sch:assert test="count(cmd:ResourceProxy[cmd:ResourceType='LandingPage']) le 1">[<sch:value-of select="$BPG"/>][E11] A CMD record should have no more than one Landing Page!</sch:assert>
        </sch:rule>
    </sch:pattern>
    
    <sch:pattern id="E12">
        <sch:title>E12: Provide no more than one SearchPage</sch:title>
        <sch:rule role="warning" context="/cmd:CMD/cmd:Resources/cmd:ResourceProxyList">
            <sch:assert test="count(cmd:ResourceProxy[cmd:ResourceType='SearchPage']) le 1">[<sch:value-of select="$BPG"/>][E12] A CMD record should have no more than one Search Page!</sch:assert>
        </sch:rule>
    </sch:pattern>
    
    <sch:pattern id="E13">
        <sch:title>E13: Provide no more than one SearchService</sch:title>
        <sch:rule role="warning" context="/cmd:CMD/cmd:Resources/cmd:ResourceProxyList">
            <sch:assert test="count(cmd:ResourceProxy[cmd:ResourceType='SearchService']) le 1">[<sch:value-of select="$BPG"/>][E13] A CMD record should have no more than one Search Service!</sch:assert>
        </sch:rule>
    </sch:pattern>
    
    <!-- TODO E14 -->
    
    <sch:pattern id="E16">
        <sch:title>E16: Add roles to both relationship participants when considered useful</sch:title>
        <sch:rule role="warning" context="/cmd:ResourceRelation/cmd:Resource">
            <sch:assert test="normalize-space(cmd:Role)!=''">[<sch:value-of select="$BPG"/>][E16] Specify the role a resource plays in a relation!</sch:assert>
        </sch:rule>
        <sch:rule role="warning" context="/cmd:ResourceRelation/cmd:Resource/cmd:Role">
            <sch:assert test="normalize-space(@ConceptLink)!=''">[<sch:value-of select="$BPG"/>][E16] Add a Concept Link to the role of a resource in a relation!</sch:assert>
        </sch:rule>
    </sch:pattern>
    
    <sch:pattern id="E18">
        <sch:title>E18: IsPartOf may be used to express a partitive relation between the described resource as a whole and a larger resource or collection</sch:title>
        <sch:rule role="warning" context="/cmd:IsPartOfList">
            <sch:assert test="empty(cmd:IsPartOf)">[<sch:value-of select="$BPG"/>][E18] IsPartOf is not widely used or well supported by the CLARIN infrastructure!</sch:assert>
        </sch:rule>
    </sch:pattern>
    
    <!-- E19 will be checked by cmd-envelop.xsd -->
    
    <sch:pattern id="E20">
        <sch:title>E20: Delete foreign attributes before providing</sch:title>
        <sch:rule role="warning" context="cmd:Components">
            <sch:assert test="empty((ancestor::*|preceding::*)/@*[not(namespace-uri()=('','http://www.w3.org/XML/1998/namespace','http://www.w3.org/2001/XMLSchema-instance'))])">[<sch:value-of select="$BPG"/>][E20] Strip foreign attributes before providing CMD records!</sch:assert>
        </sch:rule>
    </sch:pattern>
    
    <!-- TODO: CS3 -->
    
    <!-- TODO: CS5 -->
    
</sch:schema>