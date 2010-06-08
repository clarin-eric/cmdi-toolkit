<?xml version="1.0" encoding="UTF-8"?>

<!-- 
    $Rev: 484 $ 
    $Date$ 
-->

<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema" version="2.0">
    <xsl:template name="PrintHeader">
        <xs:element name="Header">
            <xs:complexType>
                <xs:sequence>
                    <xs:element name="MdCreator" type="xs:string" minOccurs="0"/>
                    <xs:element name="MdCreationDate" type="xs:date" minOccurs="0"/>
                    <xs:element name="MdSelfLink" type="xs:anyURI" minOccurs="0"/>
                    <xs:element name="MdProfile" type="xs:anyURI" minOccurs="0"/>
                </xs:sequence>
            </xs:complexType>
        </xs:element>
        <xs:element name="Resources">
            <xs:complexType>
                <xs:sequence>
                    <xs:element name="ResourceProxyList">
                        <xs:complexType>
                            <xs:sequence>
                                <xs:element maxOccurs="unbounded" minOccurs="0" name="ResourceProxy">
                                    <xs:complexType>
                                        <xs:sequence>
                                            <xs:element maxOccurs="1" minOccurs="1"
                                                name="ResourceType">
                                                <xs:simpleType>
                                                  <xs:restriction base="xs:string">
                                                  <xs:enumeration value="Metadata">
                                                  <xs:annotation>
                                                  <xs:documentation>The ResourceProxy
                                                  refers to another component
                                                  metadata instance (e.g. for
                                                  grouping metadata descriptions
                                                  into
                                                  collections)</xs:documentation>
                                                  </xs:annotation>
                                                  </xs:enumeration>
                                                  <xs:enumeration value="Resource">
                                                  <xs:annotation>
                                                  <xs:documentation>The ResourceProxy
                                                  refers to a file that is not a
                                                  metadata instance (e.g. a text
                                                  document)</xs:documentation>
                                                  </xs:annotation>
                                                  </xs:enumeration>
                                                  </xs:restriction>
                                                </xs:simpleType>
                                            </xs:element>
                                            <xs:element maxOccurs="1" minOccurs="1"
                                                name="ResourceRef" type="xs:anyURI"/>
                                        </xs:sequence>
                                        <xs:attribute name="id" type="xs:ID" use="required"/>
                                    </xs:complexType>
                                </xs:element>
                            </xs:sequence>
                        </xs:complexType>
                    </xs:element>
                    <xs:element name="JournalFileProxyList">
                        <xs:complexType>
                            <xs:sequence>
                                <xs:element maxOccurs="unbounded" minOccurs="0"
                                    name="JournalFileProxy">
                                    <xs:complexType>
                                        <xs:sequence>
                                            <xs:element maxOccurs="1" minOccurs="1"
                                                name="JournalFileRef" type="xs:anyURI"/>
                                        </xs:sequence>
                                    </xs:complexType>
                                </xs:element>
                            </xs:sequence>
                        </xs:complexType>
                    </xs:element>
                    <xs:element name="ResourceRelationList">
                        <xs:complexType>
                            <xs:sequence>
                                <xs:element maxOccurs="unbounded" minOccurs="0"
                                    name="ResourceRelation">
                                    <xs:complexType>
                                        <xs:sequence>
                                            <xs:element maxOccurs="1" minOccurs="1"
                                                name="RelationType"/>
                                            <xs:element maxOccurs="1" minOccurs="1" name="Res1">
                                                <xs:complexType>
                                                  <xs:attribute name="ref" type="xs:IDREF"/>
                                                </xs:complexType>
                                            </xs:element>
                                            <xs:element maxOccurs="1" minOccurs="1" name="Res2">
                                                <xs:complexType>
                                                  <xs:attribute name="ref" type="xs:IDREF"/>
                                                </xs:complexType>
                                            </xs:element>
                                        </xs:sequence>
                                    </xs:complexType>
                                </xs:element>
                            </xs:sequence>
                        </xs:complexType>
                    </xs:element>
                    
                    <xs:element minOccurs="0" name="IsPartOfList">
                        <xs:complexType>
                            <xs:sequence>
                                <xs:element maxOccurs="unbounded" minOccurs="0"
                                    name="IsPartOf" type="xs:anyURI"/>
                            </xs:sequence>
                        </xs:complexType>
                    </xs:element>
                    
                </xs:sequence>
            </xs:complexType>
        </xs:element>
    </xsl:template>
</xsl:stylesheet>
