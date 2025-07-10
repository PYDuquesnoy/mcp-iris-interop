/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class Ens.Schema.DTL Extends %RegisteredObject [ ClassType = "", ProcedureBlock, System = 4 ]
{

XData Schema
{
<?xml version="1.0" ?>
<xs:schema xmlns:xs="http://www.w3.org/2001/XMLSchema" elementFormDefault="qualified" attributeFormDefault="unqualified">

<xs:complexType name="action">
<xs:sequence>
<xs:element name="annotation" minOccurs="0" maxOccurs="1"/>
</xs:sequence>
<xs:attribute name="disabled" type="xs:boolean" use="optional" default="0" />
<xs:attribute name="expanded" type="xs:boolean" use="optional" default="1" />
</xs:complexType>

<xs:complexType name="mixedaction" mixed="true">
<xs:sequence>
<xs:element name="annotation" minOccurs="0" maxOccurs="1"/>
</xs:sequence>
<xs:attribute name="disabled" type="xs:boolean" use="optional" default="0" />
<xs:attribute name="languageOverride" type="implementation_language_nullable" use="optional" />
</xs:complexType>

<xs:element name="assign">
<xs:complexType>
<xs:complexContent>
<xs:extension base="action">
<xs:attribute name="property" type="non_empty_string" use="required"/>
<xs:attribute name="languageOverride" type="implementation_language_nullable" use="optional" />
<xs:attribute name="value" type="xs:string" use="required"/>
<xs:attribute name="action" use="optional" default="set">
<xs:simpleType>
<xs:restriction base="xs:string">
<xs:enumeration value="append"/>
<xs:enumeration value="clear"/>
<xs:enumeration value="insert"/>
<xs:enumeration value="remove"/>
<xs:enumeration value="set"/>
<xs:enumeration value="copy"/>
</xs:restriction> 
</xs:simpleType>
</xs:attribute>
<xs:attribute name="key" type="non_empty_string" use="optional" default='""'/>
</xs:extension>
</xs:complexContent>
</xs:complexType>		
</xs:element>

<xs:element name="subtransform">
<xs:complexType>
<xs:complexContent>
<xs:extension base="action">
<xs:attribute name="class" type="non_empty_string" use="required"/>
<xs:attribute name="sourceObj" type="non_empty_string" use="required"/>
<xs:attribute name="targetObj" type="non_empty_string" use="required"/>
<xs:attribute name="aux" type="xs:string" use="optional"/>
</xs:extension>
</xs:complexContent>
</xs:complexType>		
</xs:element>

<xs:element name="break" type="action"/>

<xs:element name="code" type="mixedaction"/>

<xs:element name="pyFromImport" type="xs:string"/>

<xs:element name="comment" type="action"/>

<xs:element name="foreach">
<xs:complexType>
<xs:complexContent>
<xs:extension base="actions">
<xs:attribute name="property" type="non_empty_string" use="required"/>
<xs:attribute name="key" type="non_empty_string" use="required"/>
<xs:attribute name="unload" type="xs:boolean" use="optional" default="0" />
</xs:extension>
</xs:complexContent>
</xs:complexType>
</xs:element>

<xs:element name="sql" type="mixedaction"/>

<xs:element name="trace">
<xs:complexType>
<xs:complexContent>
<xs:extension base="action">
<xs:attribute name="value" type="non_empty_string" use="required"/>
<xs:attribute name="languageOverride" type="implementation_language_nullable" use="optional" />
</xs:extension>
</xs:complexContent>
</xs:complexType>
</xs:element>

<xs:element name="if">
<xs:complexType>
<xs:complexContent>
<xs:extension base="action">
<xs:choice minOccurs="1" maxOccurs="1">
<xs:sequence>
<xs:element name="true" type="actions"/>
<xs:element name="false" type="actions"/>
</xs:sequence>
<xs:sequence>
<xs:element name="false" type="actions"/>
<xs:element name="true" type="actions"/>
</xs:sequence>
<xs:sequence>
<xs:element name="true" type="actions"/>
</xs:sequence>
<xs:sequence>
<xs:element name="false" type="actions"/>
</xs:sequence>
</xs:choice>
<xs:attribute name="languageOverride" type="implementation_language_nullable" use="optional" />
<xs:attribute name="condition" type="non_empty_string" use="required"/>
</xs:extension>
</xs:complexContent>
</xs:complexType>
</xs:element>

<xs:complexType name="actions">
<xs:complexContent>
<xs:extension base="action">
<xs:choice minOccurs="0" maxOccurs="unbounded">
<xs:element ref="assign"/>
<xs:element ref="break"/>
<xs:element ref="code"/>
<xs:element ref="comment"/>
<xs:element ref="foreach"/>
<xs:element ref="group"/>
<xs:element ref="if"/>
<xs:element ref="sql"/>
<xs:element ref="subtransform"/>
<xs:element ref="switch"/>
<xs:element ref="trace"/>
<xs:element ref="pyFromImport"/>
</xs:choice>
</xs:extension>
</xs:complexContent>
</xs:complexType>

<xs:element name="transform">
<xs:complexType>
<xs:complexContent>
<xs:extension base="actions">
<!-- !!! make these 4 attr pairs into 4 choices (Class attrs required, DocType attrs optional) if we figure out how -->
<xs:attribute name="sourceClass" type="xs:string" use="optional" />
<!-- deprecated but still supported -->
<xs:attribute name="source" type="xs:string" use="optional" />
<xs:attribute name="sourceDocType" type="xs:string" use="optional"/>
<!-- deprecated but still supported -->
<xs:attribute name="sourceType" type="xs:string" use="optional"/>
<xs:attribute name="targetClass" type="xs:string" use="optional" />
<!-- deprecated but still supported -->
<xs:attribute name="target" type="xs:string" use="optional" />
<xs:attribute name="targetDocType" type="xs:string" use="optional"/>
<!-- deprecated but still supported -->
<xs:attribute name="targetType" type="xs:string" use="optional"/>

<xs:attribute name="create" default="new">
<xs:simpleType>
<xs:restriction base="xs:string">
<xs:enumeration value="new"/>
<xs:enumeration value="copy"/>
<xs:enumeration value="existing"/>
</xs:restriction> 
</xs:simpleType>
</xs:attribute>

<xs:attribute name="language">
<xs:simpleType>
<xs:restriction base="xs:string">
<xs:enumeration value="objectscript"/>
<xs:enumeration value="basic"/>
<xs:enumeration value="python"/>
</xs:restriction> 
</xs:simpleType>
</xs:attribute>
</xs:extension>
</xs:complexContent>
</xs:complexType>
</xs:element>

<xs:simpleType name="non_empty_string">
<xs:restriction base="xs:string">
<xs:minLength value="1"/>
</xs:restriction>
</xs:simpleType>	


<xs:element name="switch">
<xs:complexType>
<xs:complexContent>
<xs:extension base="action">

<xs:sequence>
<xs:element name="case" minOccurs="0" maxOccurs="unbounded">
<xs:complexType>
<xs:complexContent>
<xs:extension base="actions">
<xs:attribute name="condition" type="non_empty_string" use="required"/>		
</xs:extension>
</xs:complexContent>
</xs:complexType>
</xs:element>
<xs:element name="default" minOccurs="0" maxOccurs="1">
<xs:complexType>
<xs:complexContent>
<xs:extension base="actions"/>
</xs:complexContent>
</xs:complexType>
</xs:element>
</xs:sequence>
<xs:attribute name="languageOverride" type="implementation_language_nullable" use="optional" />
</xs:extension>
</xs:complexContent>
</xs:complexType>
</xs:element>

<xs:element name="group">
<xs:complexType>
<xs:complexContent>
<xs:extension base="actions"/>
</xs:complexContent>
</xs:complexType>
</xs:element>

<xs:simpleType name="implementation_language_nullable">
<xs:restriction base="xs:string">
<xs:enumeration value=""/>
<xs:enumeration value="objectscript"/>
<xs:enumeration value="basic"/>
<xs:enumeration value="python"/>
</xs:restriction> 
</xs:simpleType>	

</xs:schema>
}

}
