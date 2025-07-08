/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %Net.Cloud.Storage.BlobInfo Extends %RegisteredObject [ Language = objectscript ]
{

Property bucketName As %String;

Property name As %String;

Property owner As %String;

Property size As %Integer;

Property createTime As %String;

Property updateTime As %String;

Method toJSON() As %String
{
	Set d = ##class(%DynamicObject).%New()
	Set d.bucketName = ..bucketName
	Set d.name = ..name
	Set d.owner = ..owner
	Set d.size = ..size
	Set d.createTime = ..createTime
	Set d.updateTime = ..updateTime
	Quit d.%ToJSON()
}

}
