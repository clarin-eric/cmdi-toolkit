<?xml version="1.0" encoding="UTF-8"?>
<sch:schema xmlns:sch="http://purl.oclc.org/dsdl/schematron" queryBinding="xslt2">

    <sch:ns uri="http://www.w3.org/2001/XMLSchema-instance" prefix="xsi"/>

    <!-- CE-2017-1076 - CLARIN's CMDI Best Practices Guide -->
    
    <sch:let name="BPG" value="'CE-2017-1076'"/>
    
    <sch:pattern id="C1">
        <sch:title>C1: Provide detailed documentation</sch:title>
        <sch:rule context="/ComponentSpec[@isProfile='false']/Header" role="warning">
            <sch:assert test="normalize-space(string-join(Description,' '))!=''">[<sch:value-of select="$BPG"/>][C1] The Component Description is empty!</sch:assert>
        </sch:rule>
        <sch:rule context="Component[empty(../ComponentSpec) or exists(../ComponentSpec[@isProfile='false'])][exists(@name)]" role="warning">
            <sch:assert test="normalize-space(string-join(Documentation,' '))!=''">[<sch:value-of select="$BPG"/>][C1] The Component Documentation is empty!</sch:assert>
        </sch:rule>
        <sch:rule context="Element" role="warning">
            <sch:assert test="normalize-space(string-join(Documentation,' '))!=''">[<sch:value-of select="$BPG"/>][C1] The Element Documentation is empty!</sch:assert>
        </sch:rule>
        <sch:rule context="Attribute" role="warning">
            <sch:assert test="normalize-space(string-join(Documentation,' '))!=''">[<sch:value-of select="$BPG"/>][C1] The Attribute Documentation is empty!</sch:assert>
        </sch:rule>
    </sch:pattern>
    
    <sch:pattern id="C5">
        <sch:title>C5: Aim for a uniform naming pattern</sch:title>
        <sch:rule context="Component[exists(@name)]" role="warning">
            <sch:let name="prev" value="((ancestor::Component|preceding::Component)/@name)[1]"/>
            <sch:assert test="empty($prev) or replace(replace(substring(@name,1,1),'[a-z]','a'),'[A-Z]','A')=replace(replace(substring($prev,1,1),'[a-z]','a'),'[A-Z]','A')">[<sch:value-of select="$BPG"/>][C5] Preceding Component[<sch:value-of select="$prev"/>] uses another naming pattern than this Component[<sch:value-of select="@name"/>]!</sch:assert>
        </sch:rule>
        <sch:rule context="Element" role="warning">
            <sch:let name="prev" value="(preceding::Element/@name)[1]"/>
            <sch:assert test="empty($prev) or replace(replace(substring(@name,1,1),'[a-z]','a'),'[A-Z]','A')=replace(replace(substring($prev,1,1),'[a-z]','a'),'[A-Z]','A')">[<sch:value-of select="$BPG"/>][C5] Preceding Element[<sch:value-of select="$prev"/>] uses another naming pattern than this Element[<sch:value-of select="@name"/>]!</sch:assert>
        </sch:rule>
        <sch:rule context="Attribute" role="warning">
            <sch:let name="prev" value="(preceding::Attribute/@name)[1]"/>
            <sch:assert test="empty($prev) or replace(replace(substring(@name,1,1),'[a-z]','a'),'[A-Z]','A')=replace(replace(substring($prev,1,1),'[a-z]','a'),'[A-Z]','A')">[<sch:value-of select="$BPG"/>][C5] Preceding Attribute[<sch:value-of select="$prev"/>] uses another naming pattern than this Attribute[<sch:value-of select="@name"/>]!</sch:assert>
        </sch:rule>
    </sch:pattern>
    
    <sch:pattern id="C7">
        <sch:title>C7: Use an appropriate restricitive value scheme</sch:title>
        <sch:rule context="Element|Attribute" role="warning">
            <sch:assert test="(exists(@ValueScheme) and @ValueScheme!='string') or exists(ValueScheme)">[<sch:value-of select="$BPG"/>][C7] Is a string value scheme really needed, or is a more restrictive value scheme more appropriate?</sch:assert>
        </sch:rule>
    </sch:pattern>
    
    <sch:pattern id="C8">
        <sch:title>C8: Prefer elements over attributes</sch:title>
        <sch:rule context="Attribute" role="warning">
            <sch:assert test="false()">[<sch:value-of select="$BPG"/>][C8] Is an attribute really needed, or is an element also ok?</sch:assert>
        </sch:rule>
    </sch:pattern>

    <sch:pattern id="C9">
        <sch:title>C9: Prefer vocabularies over Booleans</sch:title>
        <sch:rule context="Element|Attribute" role="warning">
            <sch:assert test="@ValueScheme!='boolean'">[<sch:value-of select="$BPG"/>][C9] Is a boolean value scheme really needed, or is a more explicit vocabulary more appropriate?</sch:assert>
        </sch:rule>
    </sch:pattern>
    
    <sch:pattern id="C11">
        <sch:title>C11: Reuse or recycle components where possible</sch:title>
        <sch:rule context="/ComponentSpec[@isProfile='false']//Component/Component" role="warning">
            <sch:assert test="empty(@name)">[<sch:value-of select="$BPG"/>][C11] Is an inner Component really needed, or could this be an external, reusable, component more appropriate?</sch:assert>
        </sch:rule>
    </sch:pattern>
    
    <sch:pattern id="C12">
        <sch:title>C12: Prefer controlled vocabularies</sch:title>
        <!-- CHECK: overlap with C7, C9 -->
        <!-- NOTE: how 'free' is an non-string datatype, maybe only trigger when @ValueScheme!='string'? -->
        <sch:rule context="Element|Attribute" role="warning">
            <sch:assert test="empty(@ValueScheme) and (exists(ValueScheme/Vocabulary/enumeration/item) or exists(ValueScheme/pattern))">[<sch:value-of select="$BPG"/>][C12] Is a free value scheme really needed, or is a controlled vocabulary or pattern more appropriate?</sch:assert>
        </sch:rule>
    </sch:pattern>
    
    <sch:pattern id="C13">
        <sch:title>C13: Make use of @cmd:ConceptLink</sch:title>
        <!-- CHECK: overlap with C14 -->
        <sch:rule context="item" role="warning">
            <sch:assert test="normalize-space(@ConceptLink)!=''">[<sch:value-of select="$BPG"/>][C13] Make the semantics of the vocabulary item explicit by adding a concept link.</sch:assert>
        </sch:rule>
    </sch:pattern>
    
    <sch:pattern id="C14">
        <sch:title>C14: Add concept links to all elements, attributes and vocabulary items</sch:title>
        <sch:rule context="Element|Attribute|item" role="warning">
            <sch:assert test="normalize-space(@ConceptLink)!=''">[<sch:value-of select="$BPG"/>][C14] Make the semantics of the element, attribute or vocabulary item explicit by adding a concept link.</sch:assert>
        </sch:rule>
    </sch:pattern>
    
    <sch:pattern id="C15">
        <sch:title>C15: Add concept links to salient components</sch:title>
        <sch:rule context="Component/Component" role="warning">
            <sch:assert test="exists(@name) and normalize-space(@ConceptLink)!=''">[<sch:value-of select="$BPG"/>][C15] Make the semantics of the component explicit by adding a concept link.</sch:assert>
        </sch:rule>
        <sch:rule context="ComponentSpec/Component" role="warning">
            <sch:assert test="normalize-space(@ConceptLink)!=''">[<sch:value-of select="$BPG"/>][C15] Make the semantics of the salient component explicit by adding a concept link.</sch:assert>
        </sch:rule>
    </sch:pattern>
    
    <!-- TODO: C16 - CCR coordinators didn't approve concepts yet, CLARIN-NL did -->
    
    <sch:pattern id="C18">
        <sch:title>C18: Refer to a persistent semantic registry</sch:title>
        <!-- NOTE: http://cdb.iso.org/lg/CDB-* is legacy -->
        <sch:rule context="*[exists(@ConceptLink)]" role="warning">
            <sch:assert test="matches(@ConceptLink,'^(http(s)?://hdl.handle.net/|hdl:)11459/CCR_.*$') or matches(@ConceptLink,'^http(s)?://purl.org/dc/.*$') or matches(@ConceptLink,'^http://cdb.iso.org/lg/CDB-.*$')">[<sch:value-of select="$BPG"/>][C18] The concept link should refer to a persistent registry.</sch:assert>
        </sch:rule>
    </sch:pattern>
    
    <sch:pattern id="P1">
        <sch:title>P1: Reuse components</sch:title>
        <!-- CHECK: overlap with C11 -->
        <sch:rule context="/ComponentSpec[@isProfile='true']//Component/Component" role="warning">
            <sch:assert test="empty(@name)">[<sch:value-of select="$BPG"/>][P1] Is an inner Component really needed, or could this be an external, reusable, component more appropriate?</sch:assert>
        </sch:rule>
    </sch:pattern>
    
    <sch:pattern id="P4">
        <sch:title>P4: Use Documentation</sch:title>
        <!-- CHECK: overlap with C1 -->
        <sch:rule context="/ComponentSpec[@isProfile='true']/Header" role="warning">
            <sch:assert test="normalize-space(string-join(Description,' '))!=''">[<sch:value-of select="$BPG"/>][P4] The Profile Description is empty!</sch:assert>
        </sch:rule>
        <sch:rule context="/ComponentSpec[@isProfile='true']/Component[exists(@name)]" role="warning">
            <sch:assert test="normalize-space(string-join(Documentation,' '))!=''">[<sch:value-of select="$BPG"/>][P4] The Component Documentation is empty!</sch:assert>
        </sch:rule>
    </sch:pattern>
    
    <!-- TODO: P5 - what is the minimal set of concepts? -->
    
</sch:schema>