<?xml version="1.0" encoding="UTF-8"?>
<sch:schema xmlns:sch="http://purl.oclc.org/dsdl/schematron" queryBinding="xslt2">
    <sch:ns uri="http://www.w3.org/2001/XMLSchema-instance" prefix="xsi"/>
 
    <sch:pattern id="c_nest">
        <sch:title>Check nesting</sch:title>
        <sch:rule context="Component[exists(Component|Element)]" role="warning">
            <sch:assert test="empty((Component|Element)[@name=current()/@name])">
                [CMDI Best Practices] A nested component or element has the same name ('<sch:value-of select="@name"/>') as this component! Please, consider to rename one of them.
            </sch:assert>
        </sch:rule>
    </sch:pattern>
    
    <sch:pattern id="a_nest">
        <sch:title>Check attribute nesting</sch:title>
        <sch:rule context="Attribute" role="warning">
            <sch:assert test="empty((ancestor::Component|ancestor::Element)[1][@name=current()/@name])">
                [CMDI Best Practices] An attribute has the same name ('<sch:value-of select="@name"/>') as its element or component! Please, consider to rename one of them.
            </sch:assert>
        </sch:rule>
    </sch:pattern>
    
</sch:schema>