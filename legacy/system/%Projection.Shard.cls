/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include %BigData.ShardingManager

/// Projection class called for any sharded table
Class %Projection.Shard Extends AbstractProjection
{

/// This method is called by the Class Compiler whenever an associated 
/// class has finished compiling. <var>classname</var> contains the name of 
/// the associated class while <var>parameters</var> contains an array of the 
/// projection parameters subscripted by parameter name. Also the special parameter value
/// parameters("%qstruct") contains a merge of the qstruct array this projection is being
/// compiled with. The <var>modified</var> is always blank.<br>
/// Any errors reported by this method are reported by the Class Compiler but
/// do not effect class compilation in any way.
ClassMethod CreateProjection(classname As %String, ByRef parameters As %String, modified As %String, qstruct) As %Status
{
	$$$SNRBDebugTrace("CreateProjection stack:",$zu(41,-2))
	$$$SNRBDebugTrace("CreateProjection parameters: "_$g(parameters)_" modified: "_$g(modified)_" qstruct: "_$g(qstruct))
	RETURN:(classname="%Storage.Shard"||+$g(%SNConvertingToNonSharded)) $$$OK  // JMM1152=
	#;set extent="" //$$RootExtent^%occLibrary(classname)
	#;set:extent="" extent=classname
	if $$$SSIsFederated(classname) {
		// Federated table: Just create a dummy shard map entry.  Federated tables don't really have shard maps,
		// but sharding looks for an entry here to confirm it can handle queries against this table.
		s $$$SSGlobal($$$SSStorageModelSQL,$$$SSEntitiesSubscript,classname,$$$SSShardMapSubscript)=$$$SSShardMapTypeFederated
		s $$$SSGlobal($$$SSStorageModelSQL,$$$SSEntitiesSubscript,classname,$$$SSShardMapSubscript,$$$SSShardCountSubscript)=$$$SSGlobal($$$SSShardsSubscript)
		RETURN $$$OK
	}
	RETURN ##class(%BigData.ShardedSQL).%ShardClass(classname, classname)
}

/// This method is called by the Class Compiler whenever an associated 
/// class is either a) about to be recompiled, or b) about to be deleted.
/// <var>classname</var> contains the name of the associated class while 
/// <var>parameters</var> contains an array of the projection parameters 
/// subscripted by parameter name.  Also the special parameter value
/// parameters("%qstruct") contains a merge of the qstruct array this projection is being
/// uncompiled/deleted with. <var>recompile</var> is true (1) if the
/// associated class is about to be recompiled. The <var>modified</var> is always blank.<br>
/// Any errors reported by this method are reported by the Class Compiler but
/// do not effect class compilation in any way.
ClassMethod RemoveProjection(classname As %String, ByRef parameters As %String, recompile As %Boolean, modified As %String, qstruct) As %Status
{
	Quit:recompile $$$OK  // Only propagate to shards when class is about to be deleted
	If classname="%Storage.Shard" Quit $$$OK
	if $$$SSIsFederated(classname) {
		k $$$SSGlobal($$$SSStorageModelSQL,$$$SSEntitiesSubscript,classname)
		RETURN $$$OK
	}
	Set table=$get($$$EXTtablename($$$pEXT,classname)),schema=$get($$$EXTschema($$$pEXT,classname))
	If table=""||(schema="") Quit $$$OK
	set deleteextent=$g(parameters("%qstruct","deleteextent"))
	return ##class(%BigData.ShardedSQL).%DropTable(classname, schema_"."_table,deleteextent)  // 4th argument qstruct has the qspec in the root node
}

}
