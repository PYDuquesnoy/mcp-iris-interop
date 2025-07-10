/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Business Service to consume data from complex batch files received via FTP using the RecordMap parsing framework.
Class EnsLib.RecordMap.Service.ComplexBatchFTPService Extends EnsLib.RecordMap.Service.ComplexBatchFileService [ System = 4 ]
{

Parameter ADAPTER = "EnsLib.FTP.InboundAdapter";

}
