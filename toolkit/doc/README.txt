$Revision$
$Date$

How to use this XML-toolkit for the CLARIN component-metadata framework?

1. create components that comply to general-component-schema.xsd

example of such a component: example-component-actor.xml

2. create a profile that consists of included components

example: example-profile-instance.xml

3. now transform the profile using comp2schema.xsl

example result: example-md-schema.xsd

4. finally use the generated schema to create a metadata instance

example: example-md-instance.xml

For more information, see the CLARIN website at:
http://www.clarin.eu/node/2470/

