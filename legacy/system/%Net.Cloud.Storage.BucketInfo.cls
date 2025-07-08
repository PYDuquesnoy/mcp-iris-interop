/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %Net.Cloud.Storage.BucketInfo Extends %RegisteredObject [ Language = objectscript ]
{

Property name As %String;

Property owner As %String;

Property createTime As %String;

Property updateTime As %String;

Method toJSON() As %String
{
	Set d = ##class(%DynamicObject).%New()
	Set d.name = ..name
	Set d.owner = ..owner
	Set d.createTime = ..createTime
	Set d.updateTime = ..updateTime
	Quit d.%ToJSON()
}

}
