/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include %BigData.ShardingManager

/// Context for Shared Nothing (aka Sharding)
Class %SYSTEM.Context.SN Extends %RegisteredObject
{

Property shardingManager As %BigData.ShardingManager;

Property com As %BigData.Messaging;

Property defaultPort As %Integer;

Property messagingType As %String;

Property connectionSequence As %Integer;

Property queryIdSequence As %Integer;

Property openQueryCount As %Integer;

Property deviceNumber As %Integer [ MultiDimensional ];

Property shardServerJobs [ MultiDimensional ];

Property ECPConnections [ MultiDimensional ];

Property resolvedHostnames [ MultiDimensional ];

Property tempfilePool [ MultiDimensional ];

Property querySem1Name As %String;

Property querySemaphore1 As %SYSTEM.Semaphore;

/// ShardWorkMgr object used for queries (subscripted by query id)
Property querySqms [ MultiDimensional ];

Property semaphores [ MultiDimensional ];

Property tempFileOffsets [ MultiDimensional ];

Property queryShardMapVersions [ MultiDimensional ];

Property globalReferences As %Integer;

Property commandsExecuted As %Integer;

Property diskReadMilliseconds As %Integer;

Property groupId As %String;

Method %OnNew() As %Library.Status
{
		s ..shardingManager=##class(%BigData.ShardingManager).%New()
		s ..com=##class(%BigData.TCPMessaging).%New("")
		s ..defaultPort=$$$SSDefaultPort
		s ..messagingType=$$$SSECPMessaging
		s ..connectionSequence=0
		s ..deviceNumber=$$$SNDefaultDeviceNumber
		return $$$OK
}

}
