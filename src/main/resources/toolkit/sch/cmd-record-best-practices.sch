<schema xmlns="http://purl.oclc.org/dsdl/schematron" queryBinding="xslt2">
    <ns uri="http://www.clarin.eu/cmd/1" prefix="cmd"/>
    <ns uri="http://www.w3.org/2001/XMLSchema-instance" prefix="xsi"/>

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

    <!-- Does the schema reside in the Component Registry? -->
    <pattern>
        <title>Test xsi:schemaLocation</title>
        <rule role="warning" context="/cmd:CMD">
            <assert test="matches(@xsi:schemaLocation,'http(s)?://catalog.clarin.eu/ds/ComponentRegistry/rest/')">
                [CMDI Best Practice] /cmd:CMD/@xsi:schemaLocation doesn't refer to a schema from the Component Registry! [Actual value was [<value-of select="@xsi:schemaLocation"/>]
            </assert>
        </rule>
    </pattern>
    
    <!-- Is there at least one ResourceProxy? -->
    <pattern>
        <title>Test for ResourceProxies</title>
        <rule role="warning" context="/cmd:CMD/cmd:Resources/cmd:ResourceProxyList">
            <assert test="count(cmd:ResourceProxy) ge 1">
                [CMDI Best Practices] There are no ResourceProxies! Does the metadata not describe any (digital) resources?
            </assert>
        </rule>
    </pattern>
    
    <!-- Can we determine the profile used? -->
    <pattern>
        <title>Test for known profile</title>
        <rule role="warning" context="/cmd:CMD">
            <assert test="matches(@xsi:schemaLocation,'clarin.eu:cr[0-9]+:p_[0-9]+') or matches(cmd:Header/cmd:MdProfile,'clarin.eu:cr[0-9]+:p_[0-9]+')">
                [CMDI Best Practice] the CMD profile of this record can't be found in the /cmd:CMD/@xsi:schemaLocation or /cmd:CMD/cmd:Header/cmd:MdProfile. The profile should be known for the record to be processed properly in the CLARIN joint metadata domain!
            </assert>
        </rule>
    </pattern>
    
    <!-- Do the MdProfile and the @xsi:schemaLocation refer to the same profile? -->
    <pattern>
        <title>Test if MdProfile and @xsi:schemaLocation are in sync</title>
        <rule role="warning" context="/cmd:CMD[matches(@xsi:schemaLocation,'clarin.eu:cr[0-9]+:p_[0-9]+') and matches(cmd:Header/cmd:MdProfile,'clarin.eu:cr[0-9]+:p_[0-9]+')]">
            <assert test="replace(@xsi:schemaLocation,'(clarin.eu:cr[0-9]+:p_[0-9]+)','$1') = replace(cmd:Header/cmd:MdProfile,'(clarin.eu:cr[0-9]+:p_[0-9]+)','$1')">
                [CMDI Best Practice] The CMD profile referenced in the @xsi:schemaLocation is different than the one specified in /cmd:CMD/cmd:Header/cmd:MdProfile. They should be the same!
            </assert>
        </rule>
    </pattern>
    
    <!-- Is the CMD namespace bound to a schema? -->
    <pattern>
        <title>Test for CMD namespace schema binding</title>
        <rule role="warning" context="/cmd:CMD">
            <assert test="matches(@xsi:schemaLocation,'http://www.clarin.eu/cmd/1 ')">
                [CMDI Best Practice] is the CMD 1.2 namespace bound to the envelop schema?
            </assert>
        </rule>
    </pattern>
    
    <!-- Is the CMD profile namespace bound to a schema? -->
    <pattern>
        <title>Test for CMD profile namespace schema binding</title>
        <rule role="warning" context="/cmd:CMD">
            <assert test="matches(@xsi:schemaLocation,'http://www.clarin.eu/cmd/1/profiles/')">
                [CMDI Best Practice] is the CMD 1.2 profile namespace bound to the profile schema?
            </assert>
        </rule>
    </pattern>
    
    <!-- if the following rules trigger XSD validation will (have) fail(ed)! -->
    
    <!-- Is the cmd:CMD root there? -->
    <pattern>
        <title>Test for cmd:CMD root</title>
        <rule role="warning" context="/">
            <assert test="exists(cmd:CMD)">
                [CMDI violation] is this really a CMD record? Is the namespace properly declared, e.g., including ending slash?
            </assert>
        </rule>
    </pattern>
    
</schema>
