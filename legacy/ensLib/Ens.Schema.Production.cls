/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class Ens.Schema.Production Extends %RegisteredObject [ ClassType = "", ProcedureBlock, System = 4 ]
{

XData Schema
{
<?xml version="1.0" ?>
<xs:schema xmlns:xs="http://www.w3.org/2001/XMLSchema" elementFormDefault="qualified" attributeFormDefault="unqualified">
<xs:element name="Production">
<xs:complexType>
<xs:sequence>
<xs:element name="Description" type="xs:string" minOccurs="0"/>
<xs:element name="ActorPoolSize" type="xs:integer" minOccurs="0"/>
<xs:element ref="Setting" minOccurs="0" maxOccurs="unbounded"/>
<xs:element ref="Item" minOccurs="0" maxOccurs="unbounded"/>
<xs:element name="SubProduction" minOccurs="0" maxOccurs="unbounded">
<xs:complexType>
<xs:simpleContent>
<xs:extension base="xs:string">
<xs:attribute name="Enabled" type="xs:boolean" use="optional"/>
</xs:extension>
</xs:simpleContent>
</xs:complexType>
</xs:element>
</xs:sequence>
<xs:attribute name="Name" type="non_empty_string" use="optional"/>
<xs:attribute name="TestingEnabled" type="xs:boolean" use="optional"/>
<xs:attribute name="LogGeneralTraceEvents" type="xs:boolean"  default="false"/>
</xs:complexType>		
</xs:element>

<xs:element name="Item">
<xs:complexType>
<xs:sequence>
<xs:element ref="Setting" minOccurs="0" maxOccurs="unbounded"/>
</xs:sequence>
<xs:attribute name="ClassName" type="non_empty_string" use="required"/>
<xs:attribute name="Enabled" type="xs:boolean" default="true"/>
<xs:attribute name="Foreground" type="xs:boolean" default="false"/>
<xs:attribute name="Name" type="non_empty_string" use="optional"/>
<xs:attribute name="PoolSize" type="xs:integer" use="optional"/>
<xs:attribute name="LogTraceEvents" type="xs:boolean"  default="false"/>
<xs:attribute name="DisableErrorTraps" type="xs:boolean" default="false"/>
<xs:attribute name="InactivityTimeout" type="xs:integer" default="0"/>
<xs:attribute name="Comment" type="xs:string" use="optional"/>
<xs:attribute name="Category" type="xs:string" use="optional"/>
<xs:attribute name="Schedule" type="xs:string" use="optional"/>
</xs:complexType>
</xs:element>

<xs:element name="Setting">
<xs:complexType>
<xs:simpleContent>
<xs:extension base="xs:string">
<xs:attribute name="Name" type="non_empty_string" use="required"/>
<xs:attribute name="Target" type="non_empty_string" use="optional"/>
</xs:extension>
</xs:simpleContent>
</xs:complexType>
</xs:element>

<xs:simpleType name="non_empty_string">
<xs:restriction base="xs:string">
<xs:minLength value="1"/>
</xs:restriction>
</xs:simpleType>
	
</xs:schema>
}

}
