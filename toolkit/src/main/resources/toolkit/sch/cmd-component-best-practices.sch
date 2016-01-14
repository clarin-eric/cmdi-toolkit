<?xml version="1.0" encoding="UTF-8"?>
<sch:schema xmlns:sch="http://purl.oclc.org/dsdl/schematron" queryBinding="xslt2">
    <sch:ns uri="http://www.clarin.eu/cmd/" prefix="cmd"/>
    <sch:ns uri="http://www.w3.org/2001/XMLSchema-instance" prefix="xsi"/>
 
    <sch:pattern id="c_nest">
        <sch:title>Check nesting</sch:title>
        <sch:rule context="Component[exists(Component|Element)]" role="warning">
            <sch:assert test="empty((Component|Element)[@name=current()/@name])">A nested component or element has the same name ('<sch:value-of select="@name"/>') as this component! Please, consider to rename one of them.</sch:assert>
        </sch:rule>
    </sch:pattern>
    
</sch:schema>