/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class Ens.Schema.BPL Extends %RegisteredObject [ ClassType = "", ProcedureBlock, System = 4 ]
{

XData Schema
{
<?xml version="1.0" ?>
<xs:schema xmlns:xs="http://www.w3.org/2001/XMLSchema" elementFormDefault="qualified" attributeFormDefault="unqualified">

<xs:element name="alert">
<xs:complexType>
<xs:complexContent>
<xs:extension base="activity">
<xs:attribute name="value" type="non_empty_string" use="required"/>
</xs:extension>
</xs:complexContent>
</xs:complexType>
</xs:element>

<xs:element name="assign">
<xs:complexType>
<xs:complexContent>
<xs:extension base="activity">
<xs:attribute name="property" type="non_empty_string" use="required"/>
<xs:attribute name="value" type="non_empty_string" use="required"/>
<xs:attribute name="action" use="optional" default="set">
<xs:simpleType>
<xs:restriction base="xs:string">
<xs:enumeration value="append"/>
<xs:enumeration value="clear"/>
<xs:enumeration value="copy"/>
<xs:enumeration value="insert"/>
<xs:enumeration value="remove"/>
<xs:enumeration value="set"/>
</xs:restriction> 
</xs:simpleType>
</xs:attribute>
<xs:attribute name="key" type="non_empty_string" use="optional" default='""'/>
</xs:extension>
</xs:complexContent>
</xs:complexType>		
</xs:element>

<xs:element name="branch">
<xs:complexType>
<xs:complexContent>
<xs:extension base="activity">
<xs:attribute name="condition" type="non_empty_string" use="required"/>
<xs:attribute name="label" type="non_empty_string" use="required"/>
</xs:extension>
</xs:complexContent>
</xs:complexType>
</xs:element>
<xs:element name="break" type="activity"/>

<xs:element name="call">
<xs:complexType>
<xs:complexContent>
<xs:extension base="namedActivity">
<xs:sequence>
<xs:element name="request" type="message" minOccurs="1" />
<xs:element name="response" type="message" minOccurs="0" />
</xs:sequence>
<xs:attribute name="target" type="non_empty_string" use="required"/>
<xs:attribute name="async" type="xs:boolean" use="required"/>
<xs:attribute name="timeout" type="xs:string" use="optional"/>
</xs:extension>
</xs:complexContent>
</xs:complexType>
</xs:element>

<xs:element name="catch">
<xs:complexType>
<xs:complexContent>
<xs:extension base="catchactivities">
<xs:attribute name="fault" type="non_empty_string" use="required"/>	
</xs:extension>
</xs:complexContent>
</xs:complexType>
</xs:element>

<xs:element name="catchall" type="catchactivities"/>

<xs:element name="code" type="mixedactivity"/>

<xs:element name="compensate">
<xs:complexType>
<xs:complexContent>
<xs:extension base="activity">
<xs:attribute name="target" type="non_empty_string" use="required"/>
</xs:extension>
</xs:complexContent>
</xs:complexType>
</xs:element>

<xs:element name="compensationhandler" type="threadedactivities"/>

<xs:element name="continue" type="activity"/>

<xs:element name="delay">
<xs:complexType>
<xs:complexContent>
<xs:extension base="activity">
<xs:attribute name="until" type="non_empty_string" use="optional"/>
<xs:attribute name="duration" type="non_empty_string" use="optional"/>
</xs:extension>
</xs:complexContent>
</xs:complexType>
</xs:element>

<xs:element name="empty" type="activity" />

<xs:element name="foreach">
<xs:complexType>
<xs:complexContent>
<xs:extension base="activities">
<xs:attribute name="property" type="non_empty_string" use="required"/>
<xs:attribute name="key" type="non_empty_string" use="required"/>		
</xs:extension>
</xs:complexContent>
</xs:complexType>
</xs:element>

<xs:element name="flow">
<xs:complexType>
<xs:complexContent>
<xs:extension base="activity">
<xs:sequence minOccurs="0" maxOccurs="unbounded">
<xs:element ref="sequence"/>
</xs:sequence>
</xs:extension>
</xs:complexContent>
</xs:complexType>
</xs:element>

<xs:element name="if">
<xs:complexType>
<xs:complexContent>
<xs:extension base="activity">
<xs:choice minOccurs="1" maxOccurs="1">
<xs:sequence>
<xs:element name="true" type="activities"/>
<xs:element name="false" type="activities"/>
</xs:sequence>
<xs:sequence>
<xs:element name="false" type="activities"/>
<xs:element name="true" type="activities"/>
</xs:sequence>
<xs:sequence>
<xs:element name="true" type="activities"/>
</xs:sequence>
<xs:sequence>
<xs:element name="false" type="activities"/>
</xs:sequence>
</xs:choice>
<xs:attribute name="condition" type="non_empty_string" use="required"/>
</xs:extension>
</xs:complexContent>
</xs:complexType>
</xs:element>

<xs:element name="label" type="activity" />

<xs:element name="milestone">
<xs:complexType>
<xs:complexContent>
<xs:extension base="activity">
<xs:attribute name="value" type="non_empty_string" use="required"/>
</xs:extension>
</xs:complexContent>
</xs:complexType>
</xs:element>

<xs:element name="process">
<xs:complexType>
<xs:sequence>
<xs:element name="pyFromImport" type="xs:string" minOccurs="0" maxOccurs="1"/>
<xs:element name="context" minOccurs="0">
<xs:complexType>
<xs:sequence>
<xs:element name="property" minOccurs="0" maxOccurs="unbounded">
<xs:complexType>
<xs:sequence>
<xs:element name="annotation" minOccurs="0" maxOccurs="1"/>
<xs:element name="parameters" minOccurs="0" maxOccurs="1">
<xs:complexType>
<xs:sequence>
<xs:element name="parameter" minOccurs="0" maxOccurs="unbounded">
<xs:complexType>
<xs:attribute name="name" type="non_empty_string" use="required"/>
<xs:attribute name="value" type="xs:string" use="required"/>
</xs:complexType>
</xs:element>
</xs:sequence>
</xs:complexType>
</xs:element>
</xs:sequence>
<xs:attribute name="name" type="non_empty_string" use="required"/>
<xs:attribute name="type" type="non_empty_string" use="optional"/>
<xs:attribute name="initialexpression" type="xs:string" use="optional"/>
<xs:attribute name="instantiate" type="xs:boolean" use="optional" default="false"/>
<xs:attribute name="collection" use="optional">
<xs:simpleType>
<xs:restriction base="xs:string">
<xs:enumeration value="array"/>
<xs:enumeration value="list"/>
<xs:enumeration value="binarystream"/>
<xs:enumeration value="characterstream"/>
</xs:restriction> 
</xs:simpleType>
</xs:attribute>
</xs:complexType>
</xs:element>
</xs:sequence>
</xs:complexType>
</xs:element>
<xs:element ref="sequence" minOccurs="0" maxOccurs="unbounded" />
</xs:sequence>

<xs:attribute name="request" type="non_empty_string" use="required" />
<xs:attribute name="response" type="non_empty_string" use="optional"/>
<xs:attribute name="language" type="implementation_language"/>
<xs:attribute name="component" type="xs:boolean" use="optional"/>
<xs:attribute name="contextsuperclass" type="non_empty_string" use="optional"/>
<xs:attribute name="includes" type="non_empty_string" use="optional"/>
<xs:attribute name="version" type="non_empty_string" use="optional"/>
<xs:attribute name="layout">
<xs:simpleType>
<xs:restriction base="xs:string">
<xs:enumeration value="automatic"/>
<xs:enumeration value="manual"/>
</xs:restriction> 
</xs:simpleType>
</xs:attribute>
<xs:attribute name="height" type="xs:integer" use="optional"/>
<xs:attribute name="width" type="xs:integer" use="optional"/>
</xs:complexType>
</xs:element>

<xs:element name="receive">
<xs:complexType>
<xs:complexContent>
<xs:extension base="namedActivity">
<xs:attribute name="request" type="non_empty_string" use="required"/>
<xs:attribute name="timeout" type="xs:string" use="optional"/>
</xs:extension>
</xs:complexContent>
</xs:complexType>
</xs:element>

<xs:element name="reply" type="activity"/>

<xs:element name="rule">
<xs:complexType>
<xs:complexContent>
<xs:extension base="namedActivity">
<xs:attribute name="rule" type="non_empty_string" use="required"/>
<xs:attribute name="resultLocation" type="xs:string" use="optional"/>
<xs:attribute name="reasonLocation" type="xs:string" use="optional"/>
<xs:attribute name="ruleContext" type="xs:string" use="optional"/>
</xs:extension>
</xs:complexContent>
</xs:complexType>
</xs:element>

<xs:element name="scope">
<xs:complexType>
<xs:complexContent>
<xs:extension base="activities">
<xs:sequence>
<xs:element name="compensationhandlers" minOccurs="0" maxOccurs="1">
<xs:complexType>
<xs:sequence>
<xs:element ref="compensationhandler" minOccurs="0" maxOccurs="unbounded"/>
</xs:sequence>
</xs:complexType>
</xs:element>
<xs:element name="faulthandlers" minOccurs="1" maxOccurs="1">
<xs:complexType>
<xs:choice minOccurs="1" maxOccurs="unbounded">
<xs:sequence>
<xs:element ref="catch" minOccurs="1" maxOccurs="unbounded"/>
<xs:element ref="catchall" minOccurs="0" maxOccurs="1"/>
</xs:sequence>
<xs:sequence>
<xs:element ref="catch" minOccurs="0" maxOccurs="unbounded"/>
<xs:element ref="catchall" minOccurs="1" maxOccurs="1"/>
</xs:sequence>
</xs:choice>
</xs:complexType>
</xs:element>
</xs:sequence>
</xs:extension>
</xs:complexContent>
</xs:complexType>
</xs:element>

<xs:element name="sequence" type="activities"/>

<xs:element name="sql" type="mixedactivity"/>

<xs:element name="switch">
<xs:complexType>
<xs:complexContent>
<xs:extension base="activity">
<xs:sequence>
<xs:element name="case" maxOccurs="unbounded">
<xs:complexType>
<xs:complexContent>
<xs:extension base="activities">
<xs:attribute name="condition" type="non_empty_string" use="required"/>			
</xs:extension>
</xs:complexContent>
</xs:complexType>
</xs:element>
<xs:element name="default" minOccurs="0">
<xs:complexType>
<xs:complexContent>
<xs:extension base="activities"/>
</xs:complexContent>
</xs:complexType>
</xs:element>
</xs:sequence>
</xs:extension>
</xs:complexContent>
</xs:complexType>
</xs:element>

<xs:element name="sync">
<xs:complexType>
<xs:complexContent>
<xs:extension base="activity">
<xs:attribute name="calls" type="non_empty_string" use="required"/>
<xs:attribute name="timeout" type="xs:string" use="optional"/>
<xs:attribute name="type" use="optional" default="all">
<xs:simpleType>
<xs:restriction base="xs:string">
<xs:enumeration value="all"/>
<xs:enumeration value="any"/>
</xs:restriction>
</xs:simpleType>
</xs:attribute>
<xs:attribute name="allowresync" type="xs:boolean" use="optional" default="false"/> 
</xs:extension>
</xs:complexContent>
</xs:complexType>
</xs:element>

<xs:element name="throw">
<xs:complexType>
<xs:complexContent>
<xs:extension base="activity">
<xs:attribute name="fault" type="non_empty_string" use="required"/>
</xs:extension>
</xs:complexContent>
</xs:complexType>
</xs:element>

<xs:element name="trace">
<xs:complexType>
<xs:complexContent>
<xs:extension base="activity">
<xs:attribute name="value" type="non_empty_string" use="required"/>
</xs:extension>
</xs:complexContent>
</xs:complexType>
</xs:element>

<xs:element name="transform">
<xs:complexType>
<xs:complexContent>
<xs:extension base="activity">
<xs:attribute name="class" type="xs:string" use="required"/>
<xs:attribute name="source" type="xs:string" use="required"/>
<xs:attribute name="target" type="xs:string" use="required"/>
<xs:attribute name="aux"    type="xs:string" use="optional"/>
</xs:extension>
</xs:complexContent>
</xs:complexType>
</xs:element>

<xs:element name="until">
<xs:complexType>
<xs:complexContent>
<xs:extension base="activities">
<xs:attribute name="condition" type="non_empty_string" use="required"/>			
</xs:extension>
</xs:complexContent>
</xs:complexType>
</xs:element>

<xs:element name="while">
<xs:complexType>
<xs:complexContent>
<xs:extension base="activities">
<xs:attribute name="condition" type="non_empty_string" use="required"/>			
</xs:extension>
</xs:complexContent>
</xs:complexType>
</xs:element>

<xs:element name="xpath">
<xs:complexType>
<xs:complexContent>
<xs:extension base="activity">
<xs:attribute name="source" type="non_empty_string" use="required"/>
<xs:attribute name="property" type="non_empty_string" use="required"/>
<xs:attribute name="context" type="non_empty_string" use="required"/>
<xs:attribute name="expression" type="non_empty_string" use="required"/>
<xs:attribute name="prefixmappings" type="xs:string" use="optional"/>
<xs:attribute name="schemaspec" type="xs:string" use="optional"/>
</xs:extension>
</xs:complexContent>
</xs:complexType>
</xs:element>

<xs:element name="xslt">
<xs:complexType>
<xs:complexContent>
<xs:extension base="activity">
<xs:sequence>
<xs:element name="parameters" minOccurs="0" maxOccurs="1">
<xs:complexType>
<xs:sequence>
<xs:element name="parameter" minOccurs="0" maxOccurs="unbounded">
<xs:complexType>
<xs:attribute name="name" type="non_empty_string" use="required"/>
<xs:attribute name="value" type="non_empty_string" use="required"/>
</xs:complexType>
</xs:element>
</xs:sequence>
</xs:complexType>
</xs:element>
</xs:sequence>
<xs:attribute name="xslurl" type="xs:string" use="required"/>
<xs:attribute name="source" type="xs:string" use="required"/>
<xs:attribute name="target" type="xs:string" use="required"/>
<xs:attribute name="xsltversion" use="optional" default="1.0"/>
</xs:extension>
</xs:complexContent>
</xs:complexType>
</xs:element>

<xs:attributeGroup name="activityAttributes">
<xs:attribute name="name" type="xs:string" use="optional"/>
<xs:attribute name="xpos" type="xs:integer" use="optional"/>
<xs:attribute name="ypos" type="xs:integer" use="optional"/>
<xs:attribute name="xend" type="xs:integer" use="optional"/>
<xs:attribute name="yend" type="xs:integer" use="optional"/>
<xs:attribute name="disabled" type="xs:boolean" use="optional"/>
<xs:attribute name="languageOverride" type="implementation_language_nullable" use="optional"/>
</xs:attributeGroup>

<xs:complexType name="activity">
<xs:sequence>
<xs:element name="annotation" minOccurs="0" maxOccurs="1"/>
</xs:sequence>
<xs:attributeGroup ref="activityAttributes"/>
</xs:complexType>

<xs:complexType name="mixedactivity" mixed="true">
<xs:sequence>
<xs:element name="annotation" minOccurs="0" maxOccurs="1"/>
<xs:element name="pyFromImport" type="xs:string" minOccurs="0" maxOccurs="1"/>
</xs:sequence>
<xs:attributeGroup ref="activityAttributes"/>
</xs:complexType>

<xs:complexType name="namedActivity">
<xs:complexContent>
<xs:restriction base="activity">
<xs:sequence>
<xs:element name="annotation" minOccurs="0" maxOccurs="1"/>
</xs:sequence>
<xs:attribute name="name" type="xs:string" use="required"/>
</xs:restriction>
</xs:complexContent>
</xs:complexType>

<xs:complexType name="threadedactivities">
<xs:complexContent>
<xs:extension base="activity">
<xs:choice minOccurs="0" maxOccurs="unbounded">
<xs:element ref="alert"/>
<xs:element ref="assign"/>
<xs:element ref="branch"/>
<xs:element ref="break"/>
<xs:element ref="call"/>
<xs:element ref="code"/>
<xs:element ref="continue"/>
<xs:element ref="delay"/>
<xs:element ref="empty"/>
<xs:element ref="foreach"/>
<xs:element ref="if"/>
<xs:element ref="label"/>
<xs:element ref="milestone"/>
<xs:element ref="receive"/>
<xs:element ref="reply"/>
<xs:element ref="rule"/>
<xs:element ref="scope"/>
<xs:element ref="sequence"/>
<xs:element ref="sql"/>
<xs:element ref="switch"/>
<xs:element ref="sync"/>
<xs:element ref="throw"/>
<xs:element ref="trace"/>
<xs:element ref="transform"/>
<xs:element ref="until"/>
<xs:element ref="while"/>
<xs:element ref="xslt"/>
<xs:element ref="xpath"/>
</xs:choice>
</xs:extension>
</xs:complexContent>
</xs:complexType>

<xs:complexType name="activities">
<xs:complexContent>
<xs:extension base="activity">
<xs:choice minOccurs="0" maxOccurs="unbounded">
<xs:element ref="alert"/>
<xs:element ref="assign"/>
<xs:element ref="branch"/>
<xs:element ref="break"/>
<xs:element ref="call"/>
<xs:element ref="code"/>
<xs:element ref="continue"/>
<xs:element ref="delay"/>
<xs:element ref="empty"/>
<xs:element ref="flow"/>
<xs:element ref="foreach"/>
<xs:element ref="if"/>
<xs:element ref="label"/>
<xs:element ref="milestone"/>
<xs:element ref="receive"/>
<xs:element ref="reply"/>
<xs:element ref="rule"/>
<xs:element ref="scope"/>
<xs:element ref="sequence"/>
<xs:element ref="sql"/>
<xs:element ref="switch"/>
<xs:element ref="sync"/>
<xs:element ref="throw"/>
<xs:element ref="trace"/>
<xs:element ref="transform"/>
<xs:element ref="until"/>
<xs:element ref="while"/>
<xs:element ref="xslt"/>
<xs:element ref="xpath"/>
</xs:choice>
</xs:extension>
</xs:complexContent>
</xs:complexType>


<xs:complexType name="catchactivities">
<xs:complexContent>
<xs:extension base="activity">
<xs:choice minOccurs="0" maxOccurs="unbounded">
<xs:element ref="alert"/>
<xs:element ref="assign"/>
<xs:element ref="branch"/>
<xs:element ref="break"/>
<xs:element ref="call"/>
<xs:element ref="code"/>
<xs:element ref="compensate"/>
<xs:element ref="continue"/>
<xs:element ref="delay"/>
<xs:element ref="empty"/>
<xs:element ref="foreach"/>
<xs:element ref="if"/>
<xs:element ref="label"/>
<xs:element ref="milestone"/>
<xs:element ref="receive"/>
<xs:element ref="reply"/>
<xs:element ref="rule"/>
<xs:element ref="scope"/>
<xs:element ref="sequence"/>
<xs:element ref="sql"/>
<xs:element ref="switch"/>
<xs:element ref="sync"/>
<xs:element ref="throw"/>
<xs:element ref="trace"/>
<xs:element ref="transform"/>
<xs:element ref="until"/>
<xs:element ref="while"/>
<xs:element ref="xslt"/>
<xs:element ref="xpath"/>
</xs:choice>
</xs:extension>
</xs:complexContent>
</xs:complexType>


<xs:complexType name="message">
<xs:choice minOccurs="0" maxOccurs="unbounded">
<xs:element ref="assign"/>
<xs:element ref="empty"/>
<xs:element ref="milestone"/>
<xs:element ref="trace"/>
</xs:choice>
<xs:attribute name="name" type="xs:string" use="optional"/>
<xs:attribute name="type" type="non_empty_string" use="required"/>
</xs:complexType>

<xs:simpleType name="non_empty_string">
<xs:restriction base="xs:string">
<xs:minLength value="1"/>
</xs:restriction>
</xs:simpleType>

<xs:simpleType name="implementation_language">
<xs:restriction base="xs:string">
<xs:enumeration value="objectscript"/>
<xs:enumeration value="basic"/>
<xs:enumeration value="python"/>
</xs:restriction> 
</xs:simpleType>
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

Storage Default
{
<Data name="BPLDefaultData">
<Value name="1">
<Value>%%CLASSNAME</Value>
</Value>
</Data>
<DataLocation>^Ens.Sche.BPLD</DataLocation>
<DefaultData>BPLDefaultData</DefaultData>
<IdLocation>^Ens.Sche.BPLD</IdLocation>
<IndexLocation>^Ens.Sche.BPLI</IndexLocation>
<StreamLocation>^Ens.Sche.BPLS</StreamLocation>
<Type>%Storage.Persistent</Type>
}

}
