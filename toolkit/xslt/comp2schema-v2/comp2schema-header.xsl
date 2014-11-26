<?xml version="1.0" encoding="UTF-8"?>

<!-- 
    $Rev: 484 $ 
    $Date$ 
-->

<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema" version="2.0">

    <xsl:template name="PrintHeaderType">
        <xs:simpleType name="Resourcetype_simple">
            <xs:restriction base="xs:string">
                <xs:enumeration value="Metadata">
                    <xs:annotation>
                        <xs:documentation>The ResourceProxy refers to another component metadata
                            instance (e.g. for grouping metadata descriptions into
                            collections)</xs:documentation>
                    </xs:annotation>
                </xs:enumeration>
                <xs:enumeration value="Resource">
                    <xs:annotation>
                        <xs:documentation>The ResourceProxy refers to a file that is not a metadata
                            instance (e.g. a text document)</xs:documentation>
                    </xs:annotation>
                </xs:enumeration>
                <xs:enumeration value="SearchService">
                    <xs:annotation>
                        <xs:documentation>The ResourceProxy refers to a (SRU/CQL) web service that can be used to query the resource described in this file</xs:documentation>
                    </xs:annotation>
                </xs:enumeration>
                <xs:enumeration value="SearchPage">
                    <xs:annotation>
                        <xs:documentation>The ResourceProxy refers to a web page that can be used to query the resource described in this file</xs:documentation>
                    </xs:annotation>
                </xs:enumeration>
                <xs:enumeration value="LandingPage">
                    <xs:annotation>
                        <xs:documentation>The ResourceProxy refers to a web page that contains the "original context" of the resource described in this file (e.g. repository web page displaying the metadata).</xs:documentation>
                    </xs:annotation>
                </xs:enumeration>
            </xs:restriction>
        </xs:simpleType>
    </xsl:template>


    <xsl:template name="PrintHeader">

    	<xs:element name="Header">
    		<xs:complexType>
    			<xs:sequence>
    				<xs:element name="MdCreator" minOccurs="0" maxOccurs="unbounded">
    					<xs:complexType>
    						<xs:simpleContent>
    							<xs:extension base="xs:string">
    								<xs:anyAttribute namespace="##other" processContents="lax"/>
    							</xs:extension>
    						</xs:simpleContent>
    					</xs:complexType>
    				</xs:element>
    				<xs:element name="MdCreationDate" minOccurs="0">
    					<xs:complexType>
    						<xs:simpleContent>
    							<xs:extension base="xs:date">
    								<xs:anyAttribute namespace="##other" processContents="lax"/>
    							</xs:extension>
    						</xs:simpleContent>
    					</xs:complexType>
    				</xs:element>
    				<xs:element name="MdSelfLink" minOccurs="0">
    					<xs:complexType>
    						<xs:simpleContent>
    							<xs:extension base="xs:anyURI">
    								<xs:anyAttribute namespace="##other" processContents="lax"/>
    							</xs:extension>
    						</xs:simpleContent>
    					</xs:complexType>
    				</xs:element>
    				<xs:element name="MdProfile" minOccurs="0">
    					<xs:complexType>
    						<xs:simpleContent>
    							<xs:extension base="xs:anyURI">
    								<xs:anyAttribute namespace="##other" processContents="lax"/>
    							</xs:extension>
    						</xs:simpleContent>
    					</xs:complexType>
    				</xs:element>
    				<xs:element name="MdCollectionDisplayName" minOccurs="0">
    					<xs:complexType>
    						<xs:simpleContent>
    							<xs:extension base="xs:string">
    								<xs:anyAttribute namespace="##other" processContents="lax"/>
    							</xs:extension>
    						</xs:simpleContent>
    					</xs:complexType>
    				</xs:element>
    			</xs:sequence>
    			<xs:anyAttribute namespace="##other" processContents="lax"/>
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
    										<xs:element maxOccurs="1" minOccurs="1" name="ResourceType">
    											<xs:complexType>
    												<xs:simpleContent>
    													<xs:extension base="cmd:Resourcetype_simple">
    														<xs:attribute name="mimetype" type="xs:string"/>
    														<xs:anyAttribute namespace="##other" processContents="lax"/>
    													</xs:extension>
    												</xs:simpleContent>
    											</xs:complexType>
    										</xs:element>
    										<xs:element maxOccurs="1" minOccurs="1" name="ResourceRef">
    											<xs:complexType>
    												<xs:simpleContent>
    													<xs:extension base="xs:anyURI">
    														<xs:anyAttribute namespace="##other" processContents="lax"/>
    													</xs:extension>
    												</xs:simpleContent>
    											</xs:complexType>
    										</xs:element>
    									</xs:sequence>
    									<xs:attribute name="id" type="xs:ID" use="required"/>
    									<xs:anyAttribute namespace="##other" processContents="lax"/>
    								</xs:complexType>
    							</xs:element>
    						</xs:sequence>
    						<xs:anyAttribute namespace="##other" processContents="lax"/>
    					</xs:complexType>
    				</xs:element>
    				<xs:element name="JournalFileProxyList">
    					<xs:complexType>
    						<xs:sequence>
    							<xs:element maxOccurs="unbounded" minOccurs="0" name="JournalFileProxy">
    								<xs:complexType>
    									<xs:sequence>
    										<xs:element maxOccurs="1" minOccurs="1" name="JournalFileRef">
    											<xs:complexType>
    												<xs:simpleContent>
    													<xs:extension base="xs:anyURI">
    														<xs:anyAttribute namespace="##other" processContents="lax"/>
    													</xs:extension>
    												</xs:simpleContent>
    											</xs:complexType>
    										</xs:element>
    									</xs:sequence>
    									<xs:anyAttribute namespace="##other" processContents="lax"/>
    								</xs:complexType>
    							</xs:element>
    						</xs:sequence>
    						<xs:anyAttribute namespace="##other" processContents="lax"/>
    					</xs:complexType>
    				</xs:element>
    				<xs:element name="ResourceRelationList">
    					<xs:complexType>
    						<xs:sequence>
    							<xs:element maxOccurs="unbounded" minOccurs="0" name="ResourceRelation">
    								<xs:complexType>
    									<xs:sequence>
    										<xs:element maxOccurs="1" minOccurs="1" name="RelationType">
    											<xs:complexType>
    												<xs:simpleContent>
    													<xs:extension base="xs:string">
    														<xs:anyAttribute namespace="##other" processContents="lax"/>
    													</xs:extension>
    												</xs:simpleContent>
    											</xs:complexType>
    										</xs:element>
    										<xs:element maxOccurs="1" minOccurs="1" name="Res1">
    											<xs:complexType>
    												<xs:attribute name="ref" type="xs:IDREF"/>
    												<xs:anyAttribute namespace="##other" processContents="lax"/>
    											</xs:complexType>
    										</xs:element>
    										<xs:element maxOccurs="1" minOccurs="1" name="Res2">
    											<xs:complexType>
    												<xs:attribute name="ref" type="xs:IDREF"/>
    												<xs:anyAttribute namespace="##other" processContents="lax"/>
    											</xs:complexType>
    										</xs:element>
    									</xs:sequence>
    									<xs:anyAttribute namespace="##other" processContents="lax"/>
    								</xs:complexType>
    							</xs:element>
    						</xs:sequence>
    						<xs:anyAttribute namespace="##other" processContents="lax"/>
    					</xs:complexType>
    				</xs:element>
    				
    				<xs:element minOccurs="0" name="IsPartOfList">
    					<xs:complexType>
    						<xs:sequence>
    							<xs:element maxOccurs="unbounded" minOccurs="0" name="IsPartOf">
    								<xs:complexType>
    									<xs:simpleContent>
    										<xs:extension base="xs:anyURI">
    											<xs:anyAttribute namespace="##other" processContents="lax"/>
    										</xs:extension>
    									</xs:simpleContent>
    								</xs:complexType>
    							</xs:element>
    						</xs:sequence>
    						<xs:anyAttribute namespace="##other" processContents="lax"/>
    					</xs:complexType>
    				</xs:element>
    				
    			</xs:sequence>
    			<xs:anyAttribute namespace="##other" processContents="lax"/>
    		</xs:complexType>
    	</xs:element>
    </xsl:template>
</xsl:stylesheet>
