/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include %IKInclude

Class %iKnow.Classification.UI.ClassifierBuilder Extends %DeepSee.UI.standardPage [ Deprecated, System = 4 ]
{

Parameter DOMAIN = "%iKnow";

Parameter RESOURCE = "%Development";

Parameter PAGENAME = "Text Classifier Builder";

Property definitionClass As %ZEN.Datatype.string(ZENURL = "CLASS");

Property domain As %ZEN.Datatype.integer;

Property trainingSet As %ZEN.Datatype.string;

Property classifier As %iKnow.Classification.Definition.Classifier [ Private ];

Property treeID As %ZEN.Datatype.integer [ Internal ];

Property pmml As %ZEN.Datatype.string(MAXLEN = "");

Property hideAdvanced As %ZEN.Datatype.boolean [ InitialExpression = 1 ];

Property optimizerTask As %ZEN.Datatype.integer [ InitialExpression = 1 ];

XData contentPane [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane enclosingStyle="padding:20px;">
<jsonProvider id="json" targetClass="%iKnow.Classification.Definition.Classifier"
OnGetTargetObject="OnGetClassifierObject" OnSubmitContent="SubmitClassifier" />

<modalGroup id="modBgr" groupTitle="Background process running...">
<label id="lblBgr" labelStyle="margin:10px;" />
</modalGroup>

<modalGroup id="modSave" groupTitle="Save Text Classifier model">
<vgroup labelPosition="left" cellStyle="padding-top:8px;">
<text id="txtSaveClass" label="Class name" controlStyle="width:250px;" />
</vgroup>
<button align="right" caption="Save" onclick="zenPage.saveAs(zen('txtSaveClass').getValue());" />
</modalGroup>

<modalGroup id="modNew" groupTitle="Create a new Text Classifier" >
<vgroup labelPosition="left" cellStyle="padding-top:8px;">
<text id="txtNewClass" label="Class name" controlStyle="width:250px;" 
title="Class name for this classifier" />
<select id="selNewDomain" label="Domain" title="Domain to use for training this classifier"
queryClass="%iKnow.Domain" queryName="GetAllDomains"
  onchange="zenPage.changeDomain(zenThis.getValue());" >
<parameter value="1" />
</select>
<select id="selNewMetadata" label="Category field"
title="Choose a metadata field to use as the category label for this classification model" />
</vgroup>
<hgroup labelPosition="left" enclosingStyle="padding-top:8px;">
<select id="selNewFilterField" label="Training set" 
title="Choose a metadata field to use as training vs test filter criterion"
onchange="zenPage.changeFilter(zen('selNewDomain').getValue(), zenThis.getValue(), '');" />
<spacer width="10" />
<select id="selNewFilterOperator" showEmpty="false" title="Filter operator"
onchange="zenPage.changeFilterOperator(zenThis.getValue());" />
<spacer width="10" />
<text id="selNewFilterValue" title="Filter value"
onchange="var x=zen('selNewFilterValueTest'); if (x.getValue()=='') x.setValue(zenThis.getValue());" />
</hgroup>
<hgroup labelPosition="left" enclosingStyle="padding-top:8px;">
<select id="selNewFilterFieldTest" label="Test set" title="Choose a metadata field"
onchange="zenPage.changeFilter(zen('selNewDomain').getValue(), zenThis.getValue(), 'Test');" />
<spacer width="10" />
<select id="selNewFilterOperatorTest" showEmpty="false" title="Filter operator" 
onchange="this._selNewFilterOperatorTestSet = true;" />
<spacer width="10" />
<text id="selNewFilterValueTest" title="Filter value" />
</hgroup>
<hgroup labelPosition="left" enclosingStyle="padding-top:8px;">
<select id="selNewPopulate" label="Populate terms" showEmpty="false"
title="Whether or not to populate the term list for this model based on relevance metric"
originalValue="none" value="none" valueList="none,NaiveBayes,BM25,TFIDF"
displayList="do not auto-populate term list,top n terms by NB differentiation,top n terms by BM25 score,top n terms by TFIDF score"
onchange="zen('txtNewPopulateN').setProperty('disabled',(zenThis.getValue()=='none'));" />
<spacer width="10" />
<text id="txtNewPopulateN" value="20" controlStyle="width: 30px;" disabled="true"
title="Number of terms to add when using auto-populate" />
</hgroup>
<spacer height="8" />
<button id="btnNewCreate" caption="Create" onclick="zenPage.createClassifier();" align="right" />
<button id="btnNewUpdate" caption="Update" onclick="zenPage.updateClassifier();" align="right" />
</modalGroup>

<modalGroup id="modExport" groupTitle="Export to table" >
<vgroup labelPosition="left" cellStyle="padding-top:8px">
<text id="txtExportClass" label="Class name" controlStyle="width:200px;" />
<checkbox id="chkExportOverwrite" label="Overwrite" />
</vgroup>
<button id="btnExport" caption="Export" align="right"
onclick="zenPage.Export(zen('txtExportClass').getValue(), zen('chkExportOverwrite').getValue());" />
</modalGroup>

<modalGroup id="modOptimize" groupTitle="Optimize term selection"
groupStyle="padding:10px;" width="700" >
<hgroup id="grpOptimizeStep1" cellVAlign="top">
<vgroup width="250" >
<titleBox title="Load candidates by metric" />
<spacer height="10" />
<vgroup cellStyle="padding-bottom:8px;" labelPosition="left">
<select id="selOptimizeTermMetric" label="Relevance metric" valueList="BM25,TFIDF,Dominance" value="BM25" showEmpty="false" />
<text id="txtOptimizeTermCount" label="Number of terms" value="100" controlStyle="width:80px;" />
</vgroup>
<button caption="load" align="right" 
onclick="zenPage.OptimizeLoadTerms(zen('selOptimizeTermMetric').getValue(), zen('txtOptimizeTermCount').getValue());" />
<spacer height="20" />
<titleBox title="Load candidates by SQL" />
<spacer height="10" />
<textarea id="txtOptimizeTermSQL" rows="6" cols="30" />
<spacer height="8" />
<button caption="load" align="right" onclick="zenPage.OptimizeLoadTerms('SQL', zen('txtOptimizeTermSQL').getValue());" />
</vgroup>
<spacer width="20" />
<vgroup>
<titleBox title="Candidate terms to test" />
<spacer height="10" />
<html id="htmlOptimizerTerms" OnDrawContent="DrawOptimizerTerms" 
enclosingStyle="background:white; overflow-y:scroll; width:350px; height:400px;" />
<spacer height="8" />
<button caption="next" align="right" onclick="zen('grpOptimizeStep1').setProperty('hidden',true); zen('grpOptimizeStep2').setProperty('hidden',false);" />
</vgroup>
</hgroup>
<hgroup id="grpOptimizeStep2" cellStyle="vertical-align:top;" hidden="true">
<vgroup id="modOptimizeInput" cellStyle="padding-bottom:8px;" width="250" >
<titleBox title="Settings" />
<hgroup cellVAlign="bottom">
<select id="selOptimizeTestField" label="Test set" showEmpty="false"
onchange="zenPage.changeFilter(zen('selNewDomain').getValue(), zenThis.getValue(), '');" />
<spacer width="20" />
<select id="selOptimizeTestOperator" valueList="=" showEmpty="false" />
<spacer width="20" />
<text id="txtOptimizeTestValue" />
</hgroup>
<select id="txtOptimizeMetric" label="Metric to maximize" value="MacroFmeasure" showEmpty="false"
valueList="MacroFmeasure,MacroPrecision,MacroRecall,MicroFmeasure,MicroPrecision,MicroRecall"
displayList="macro F-measure,macro precision,macro recall,micro F-measure,micro precision,micro recall" />
<text id="txtOptimizeSteps" label="Maximum number of steps" value="10" />
<text id="txtOptimizeRemoveRatio" label="Remove step ratio" value="0.1" />
<hgroup align="right">
<button caption="back" onclick="zen('grpOptimizeStep2').setProperty('hidden',true); zen('grpOptimizeStep1').setProperty('hidden',false); zen('htmlOptimizerTerms').refreshContents();" />
<button caption="start" onclick="zenPage.startOptimizer();" />
</hgroup>
</vgroup>
<spacer width="20" />
<vgroup cellStyle="padding-bottom:8px;" >
<titleBox title="Output" />
<textarea id="txtOptimizeOutput" rows="15" cols="50" readOnly="true" />
</vgroup>
</hgroup>
</modalGroup>

<hgroup cellVAlign="top" id="grpAll" disabled="true">
<vgroup id="grpTerms" width="350">
<titleBox title="Add terms" />
<spacer height="10" />
<tabGroup showTabBar="true" width="350" height="310" id="tgrTermSelection" >

<tab caption="Entities" width="100%" >
<hgroup width="100%">
<text id="txtEntities" controlStyle="width: 180px;"
title="Enter a string to find similar entities in the training dataset"
onkeyup="zenPage.exploreDelayed('Entities', zenThis.getValue());return;"
 onchange="zenPage.explore('Entities', zenThis.getValue());" />
<hgroup align="right">
<button caption="add" title="Add as individual new terms"
 onclick="zenPage.addElements('Entities','entity',true);" />
<spacer width="5" />
<button caption="append" title="Add or append as a single term"
 onclick="zenPage.addElements('Entities','entity',false);" />
</hgroup>
</hgroup>
<spacer height="5" />
<hidden id="hidEntities" />
<vgroup  enclosingClass="rgrResults" width="100%" >
<repeatingGroup id="rgrEntities" OnExecuteResultSet="ExecuteResultSet" 
queryClass="%iKnow.Queries.EntityQAPI" queryName="GetSimilar" >
<parameter value="#(%page.domain)#" />
<parameter id="rgrEntitiesSeed" />
<parameter id="rgrEntitiesPage" value="1" />
<parameter value="25" />
<parameter value="#(%page.trainingSet)#" />
<parameter value="15" />
<parameter value="0" />
<hgroup labelClass="lblTerms">
<html OnDrawContent="DrawCheckbox" seed="Entities:#(%query.entity)#" />
<label labelClass="lblTerms" label="#(%query.entity)#" width="220" />
<label labelClass="lblTerms" label="#(%query.frequency)# - #(%query.spread)#" width="70" />
</hgroup>
</repeatingGroup>
<hgroup width="100%" cellVAlign="top">
<html OnDrawContent="DrawSelectAllNone" seed="Entities" />
<hgroup align="right">
<button id="btnEntitiesPrev" caption="&lt;&lt;" disabled="true"
onclick="zenPage.exploreNext('Entities', -1);" />
<button id="btnEntitiesNext" caption="&gt;&gt;"  disabled="true"
onclick="zenPage.exploreNext('Entities', 1);" />
</hgroup>
</hgroup>
<spacer height="5" />
</vgroup>
</tab>

<tab caption="CRCs" width="100%" >
<hgroup width="100%">
<text id="txtCRCs" controlStyle="width: 180px;"
title="Enter a concept to find matching CRCs in the training dataset"
onkeyup="zenPage.exploreDelayed('CRCs', zenThis.getValue());return;"
 onchange="zenPage.explore('CRCs', zenThis.getValue());" />
<hgroup align="right">
<button caption="add" title="Add as individual terms"
 onclick="zenPage.addElements('CRCs','crc',true);" />
<spacer width="5" />
<button caption="append" title="Add or append as a single term"
 onclick="zenPage.addElements('CRCs','crc',false);" />
</hgroup>
</hgroup>
<spacer height="5" />
<hidden id="hidCRCs" />
<vgroup  enclosingClass="rgrResults" width="100%" >
<repeatingGroup id="rgrCRCs"  OnExecuteResultSet="ExecuteResultSet"
queryClass="%iKnow.Queries.CrcQAPI" queryName="GetByEntities" >
<parameter value="#(%page.domain)#" />
<parameter id="rgrCRCsSeed" />
<parameter id="rgrCRCsPage" value="1" />
<parameter value="25" />
<parameter value="#(%page.trainingSet)#" />
<parameter value="15" />
<parameter value="7" />
<hgroup labelClass="lblTerms">
<html OnDrawContent="DrawCheckbox" seed="CRCs:#(%query.head)#,#(%query.relation)#,#(%query.tail)#" />
<label labelClass="lblTerms" label="#(%query.head)# #(%query.relation)# #(%query.tail)#" width="220" />
<label labelClass="lblTerms" label="#(%query.frequency)# - #(%query.spread)#" width="70" />
</hgroup>
</repeatingGroup>
<hgroup width="100%" cellVAlign="top">
<html OnDrawContent="DrawSelectAllNone" seed="CRCs" />
<hgroup align="right">
<button id="btnCRCsPrev" caption="&lt;&lt;" disabled="true"
onclick="zenPage.exploreNext('CRCs', -1);" />
<button id="btnCRCsNext" caption="&gt;&gt;"  disabled="true"
onclick="zenPage.exploreNext('CRCs', 1);" />
</hgroup>
</hgroup>
<spacer height="5" />
</vgroup>
</tab>

<tab caption="Cooccurrences" width="100%" >
<hgroup width="100%">
<text id="txtCoocs" controlStyle="width: 180px;"
title="Enter a concept to find its cooccurrences in the training dataset"
onkeyup="zenPage.exploreDelayed('Coocs', zenThis.getValue());return;"
 onchange="zenPage.explore('Coocs', zenThis.getValue());" />
<hgroup align="right">
<button caption="add" title="Add as individual terms"
 onclick="zenPage.addElements('Coocs','cooccurrence',true);" />
<spacer width="5" />
<button caption="append" title="Add or append as a single term"
 onclick="zenPage.addElements('Coocs','cooccurrence',false);" />
</hgroup>
</hgroup>
<spacer height="5" />
<hidden id="hidCoocs" />
<vgroup  enclosingClass="rgrResults" width="100%" >
<repeatingGroup id="rgrCoocs"
sql="SELECT ? seed, * FROM %iKnow_Queries.EntityQAPI_GetRelated(?,?,?,?,?)" >
<parameter id="rgrCoocsSeed2" />
<parameter value="#(%page.domain)#" />
<parameter id="rgrCoocsSeed" />
<parameter id="rgrCoocsPage" value="1" />
<parameter value="25" />
<parameter value="#(%page.trainingSet)#" />
<hgroup labelClass="lblTerms">
<html OnDrawContent="DrawCheckbox" seed="Coocs:#(%query.seed)#,#(%query.entity)#" />
<label labelClass="lblTerms" label="#(%query.seed)#,#(%query.entity)#" width="220" />
<label labelClass="lblTerms" label="#(%query.frequency)# - #(%query.spread)#" width="70" />
</hgroup>
</repeatingGroup>
<hgroup width="100%" cellVAlign="top">
<html OnDrawContent="DrawSelectAllNone" seed="Coocs" />
<hgroup align="right">
<button id="btnCoocsPrev" caption="&lt;&lt;" disabled="true"
onclick="zenPage.exploreNext('Coocs', -1);" />
<button id="btnCoocsNext" caption="&gt;&gt;"  disabled="true"
onclick="zenPage.exploreNext('Coocs', 1);" />
</hgroup>
</hgroup>
<spacer height="5" />
</vgroup>
</tab>

<tab caption="Top" width="100%" >
<hgroup width="100%">
<label label="metric" />
<select valueList="bm25,TFIDF" showEmpty="false"
onchange="zenPage.exploreTop(zenThis.getValue());" />
<hgroup align="right">
<button caption="add" title="Add as individual terms"
 onclick="zenPage.addElements('Top','entity',true);" />
<spacer width="5" />
<button caption="append" title="Add or append as a single node"
 onclick="zenPage.addElements('Top','entity',false);" />
</hgroup>
</hgroup>
<spacer height="5" />
<hidden id="hidTop" />
<vgroup  enclosingClass="rgrResults" width="100%" >
<repeatingGroup id="rgrTop"  OnExecuteResultSet="ExecuteResultSet"
queryClass="%iKnow.Queries.EntityQAPI" queryName="GetTopBM25" >
<parameter value="#(%page.domain)#" />
<parameter id="rgrTopPage" value="1" />
<parameter value="25" />
<parameter value="#(%page.trainingSet)#" />
<parameter value="0" />
<hgroup labelClass="lblTerms">
<html OnDrawContent="DrawCheckbox" seed="Top:#(%query.entityValue)#" />
<label labelClass="lblTerms" label="#(%query.entityValue)#" width="220" />
<label labelClass="lblTerms" id="lblTopMetric" label="#(%query.bm25)#" width="70" align="right" />
</hgroup>
</repeatingGroup>
<hgroup width="100%" cellVAlign="top">
<html OnDrawContent="DrawSelectAllNone" seed="Top" />
<hgroup align="right">
<button id="btnTopPrev" caption="&lt;&lt;" disabled="true"
onclick="zenPage.exploreNext('Top', -1);" />
<button id="btnTopNext" caption="&gt;&gt;"  disabled="false"
onclick="zenPage.exploreNext('Top', 1);" />
</hgroup>
</hgroup>
<spacer height="5" />
</vgroup>
</tab>

<tab caption="SQL" width="100%" >
<textarea id="txtSQL" controlStyle="width:320px; height:90px;" 
hint="Enter a SQL query to select terms from a table"
onchange="zenPage.exploreSQL(zenThis.getValue());" />
<spacer height="5" />
<hgroup width="100%">
<label label="type" />
<select id="selSQLType" valueList="entity,crc,cooccurrence" value="entity" showEmpty="false" />
<hgroup align="right">
<button caption="add" title="Add as individual terms"
 onclick="zenPage.addElements('SQL',zen('selSQLType').getValue(),true);" />
<spacer width="5" />
<button caption="append" title="Add or append as a single term"
 onclick="zenPage.addElements('SQL',zen('selSQLType').getValue(),false);" />
</hgroup>
</hgroup>
<spacer height="5" />
<hidden id="hidSQL" />
<vgroup  enclosingClass="rgrResults" enclosingStyle="height:180px;" width="100%" >
<repeatingGroup id="rgrSQL" >
<hgroup labelClass="lblTerms">
<html id="htmlSQLCheckbox" OnDrawContent="DrawCheckbox" seed="SQL:#(%query.Value)#" />
<label id="lblSQLValue" labelClass="lblTerms" label="#(%query.Value)#" />
</hgroup>
</repeatingGroup>
<spacer height="5" />
<html OnDrawContent="DrawSelectAllNone" seed="SQL" />
</vgroup>
</tab>

</tabGroup>
<spacer height="20" />
<vgroup id="grpTermProps" labelPosition="left" cellStyle="padding-bottom:8px;" hidden="#(%page.hideAdvanced)#">
<select id="selTermNegation" label="Negation" showEmpty="false" required="true" value="undefined"
 valueList="undefined,none,no-explicit,explicit,implied" displayList="undefined,no negation,no explicit negation,explicit negation,implied negation" />
<select id="selTermCount" label="Count"  showEmpty="false" required="true" value="exactCount"
valueList="exactCount,partialCount,partialScore" displayList="occurrences,partial match count,partial match score" />
</vgroup>
</vgroup>

<spacer width="20" />

<vgroup id="grpTree" width="350">
<titleBox title="Selected terms" />
<spacer height="10" />
<dynaTree id="tree" OnGetTreeInfo="OnGetTree" enclosingStyle="height: 400px; overflow-y: scroll;"
showFolders="true" imageFolderClosed="images/contracted.gif" imageFolderOpen="images/expanded.gif"
dragEnabled="true" dropEnabled="true" ondrop="zenPage.dragTreeNode(zenThis,dragData);"
onclick="zenPage.clickTreeNode(zenThis);"  />
<spacer height="5" />
<hgroup align="right">
<button id="btnTermEdit" caption="edit" onclick="zenPage.showEditTerm();" 
title="Edit the selected term's properties" disabled="true" hidden="#(%page.hideAdvanced)#" />
<spacer width="5" />
<button id="btnTermRemove" caption="remove" onclick="zenPage.removeTerm(zen('tree').getValue());" 
title="Remove the selected term" disabled="true" />
</hgroup>

<modalGroup id="modEditTerm" groupTitle="Edit term properties">
<vgroup labelPosition="left">
<select id="selEditTermNegation" label="Negation" showEmpty="false" required="true" value="undefined"
title="Negation policy to use for this term"
 valueList="undefined,none,no-explicit,explicit,implied" displayList="undefined,no negation,no explicit negation,explicit negation,implied negation" />
<select id="selEditTermCount" label="Count"  showEmpty="false" required="true" value="exactCount"
title="What types of occurrences to count for this term"
valueList="exactCount,partialCount,partialScore" displayList="occurrences,partial match count,partial match score" />
</vgroup>
<button caption="OK" onclick="zenPage.editTerm();" />
</modalGroup>
</vgroup>

<spacer width="20" />

<vgroup id="grpModel" >
<titleBox title="Model properties" />
<spacer height="10" />
<vgroup labelPosition="left">
<text id="txtDomainName" label="Data source" readOnly="true" 
enclosingStyle="padding-bottom: 8px;" controlStyle="cursor: pointer;"
onclick="zenPage.cmdEditDataSource();" title="Click to edit data source settings for this builder" />
<select id="selMethod" label="Method" showEmpty="false"
title="The main method the model will use to categorize text"
displayList="Naive Bayes,Decision rules" valueList="naiveBayes,rules"
 enclosingStyle="padding-bottom: 8px;"
 onchange="zenPage.updateMethod(zenThis.getValue());" />
<select id="selLocalTermWeights" label="Term weights" showEmpty="false" valueList="linear,binary,logarithmic" 
title="Local term weights to use as inputs to the categorization method" 
hidden="#(%page.hideAdvanced)#" enclosingStyle="padding-bottom: 8px;"
onchange="zenPage.updateModelProp('ClassificationMethod.localTermWeights', zenThis.getValue());" />
<select id="selTermNormalization" label="Normalization" showEmpty="false" valueList="none,cosine" 
hidden="#(%page.hideAdvanced)#" enclosingStyle="padding-bottom: 8px;"
title="Whether or not to normalize the local term weights prior to feeding them into the categorization method"
onchange="zenPage.updateModelProp('ClassificationMethod.normalization', zenThis.getValue());" />
<textarea id="txtDescription" label="Description" rows="3" cols="40"
title="Description of this classification model" enclosingStyle="padding-bottom: 8px;"
onchange="zenPage.updateModelProp('description',zenThis.getValue());" />
</vgroup>

<vgroup id="grpProppmml" hidden="true">
<textarea id="txtPropPMML" controlStyle="width: 450px; height:250px;"
 onchange="zenPage.setProperty('pmml', zenThis.getValue());" />
</vgroup>

<vgroup id="grpProprules" hidden="true" cellStyle="padding-bottom: 8px;" >
<hgroup>
<select id="selPropRule" showEmpty="false" onchange="zen('drwRules').renderContents();"
title="Select a decision rule to review or edit it" />
<spacer width="10" />
<button id="btnPropRuleEdit" caption="edit" title="Edit this decision rule"
onclick="zenPage.showEditRule(zen('selPropRule').getValue());" />
<spacer width="10" />
<button id="btnPropRuleDrop" caption="drop" title="Drop this decision rule"
onclick="zenPage.dropRule(zen('selPropRule').getValue());" />
<spacer width="10" />
<button caption="add" onclick="zenPage.showEditRule(-1);" title="Add a new decision rule" />

</hgroup>
<svgFrame id="svgRules" width="450" height="200" enclosingStyle="border: 1px #333333;">
<ownerDraw id="drwRules" height="0" width="0" 
onrender="zenPage.renderRule(zen('selPropRule').getValue());" />
</svgFrame>
<vgroup labelPosition="left">
<select id="selPropRuleSelection" label="Rule selection method" valueList="firstHit,allHits" 
title="Which rule(s) should decide on the classifier outcome" showEmpty="false"
onchange="zenPage.updateModelProp('ClassificationMethod.ClassificationRules.ruleSelectionMethod', zenThis.getValue());" />
</vgroup>

<modalGroup id="modEditRule" groupTitle="Edit a classification rule" >
<vgroup labelPosition="left" cellStyle="padding-bottom:8px;">
<hidden id="hidPropRuleIndex" />
<select label="Category" id="selPropRuleCat" showEmpty="false" 
title="Category label to apply if this rule's predicate evaluates to TRUE" />
<text label="Score" id="txtPropRuleScore" value="1"
title="Optional confidence score to award if this rule's predicate evaluates to TRUE" />
<checkbox label="Fallback rule" id="chkPropRuleFallback" 
onclick="var t = zen('txtPropRuleScore'); if (t.getValue()==1) t.setValue(0.1);"
title="If checked, the rule is created without any predicates and evaluates to TRUE by default (to set a default category value)" />
</vgroup>
<vgroup width="100%">
<button caption="OK" align="right" 
onclick="zenPage.editRule(zen('selPropRuleCat').getValue(), zen('txtPropRuleScore').getValue(), zen('chkPropRuleFallback').getValue() ? 1 : 0);" />
</vgroup>
</modalGroup>

<modalGroup id="modEditPredicate" groupTitle="Edit predicate" >
<hidden id="hidPropPredicateIndex" />
<vgroup labelPosition="left" cellStyle="padding-bottom:8px;">
<select id="selPropPredicateType" label="Type"  showEmpty="false"
title="Type of predicate, either a term-based condition or boolean operator"
valueList=",AND,OR,NOT" displayList="term condition,AND,OR,NOT"
 onchange="zenPage.selectPredicateType(zen('hidPropPredicateIndex').getValue(), zenThis.getValue());" />
<select id="selPropPredicateTerm" label="Term" showEmpty="false" 
title="Term whose frequency metric is to be evaluated in this predicate" />
<select id="selPropPredicateOperator" label="Operator" showEmpty="false" title="Predicate operator"
valueList="equal,notEqual,lessThan,lessOrEqual,greaterThan,greaterOrEqual"
displayList="=,!=,&lt;,&lt;=,&gt;,&gt;=" />
<text  id="txtPropPredicateValue" label="Value" value="0" />
</vgroup>
<hgroup align="right">
<button id="btnPropPredicateDrop" caption="drop" onclick="zenPage.editPredicateDrop();"
title="Drop this predicate from its parent node" />
<spacer width="5" />
<button id="btnPropPredicateAdd" caption="add subnode" onclick="zenPage.editPredicateAdd();"
title="Add a sub-node to this predicate" />
<spacer width="5" />
<button caption="OK" onclick="zenPage.editPredicate(true);" />
</hgroup>
</modalGroup>
</vgroup>

<!-- placeholders - no configurable properties for now -->
<vgroup id="grpPropnaiveBayes" hidden="true" />
<vgroup id="grpPropcosineSimilarity" hidden="true" />
<vgroup id="grpPropeuclideanDistance" hidden="true" />
<vgroup id="grpProplinearRegression" hidden="true" />

</vgroup>
</hgroup>

</pane>
}

Method OnGetRibbonInfo(Output pDisplay As %Boolean, Output pViewIcons As %List, Output pSortOptions As %List, Output pSearchBox As %Boolean, Output pRibbonTitle As %String, Output pCommands As %List) As %Status
{
	Set pDisplay = 1
	Set pSearchBox = 0
	Set pRibbonTitle = $$$Text(..#PAGENAME)
	
	// commands
	// $LB(id,caption,help,onclick)
	set tCount = 0
	set pCommands($i(tCount)) = $lb("cmdNew",$$$Text("New"),$$$Text("Create a new Text Classifier definition"),"zenPage.cmdNew();")
	set pCommands($i(tCount)) = $lb("cmdOpen",$$$Text("Open"),$$$Text("Open an existing Text Classifier definition"),"zenPage.cmdOpen();")
	set pCommands($i(tCount)) = $lb("cmdBuild",$$$Text("Save"),$$$Text("Build the Text Classifier based on the current configuration"),"zenPage.cmdBuild();")
	set pCommands($i(tCount)) = $lb("cmdSave",$$$Text("Save as"),$$$Text("Save the Text Classifier definition to a different class"),"zenPage.cmdSave();")
	set pCommands($i(tCount)) = $lb("cmdTest",$$$Text("Test"),$$$Text("Go to the Text Classifier test page"),"zenPage.cmdTest();")
	set pCommands($i(tCount)) = $lb("cmdOptimize",$$$Text("Optimize"),$$$Text("Optimize"),"zenPage.cmdOptimize();")
	set pCommands($i(tCount)) = $lb("cmdExport",$$$Text("Export"),$$$Text("Export frequency information to a table"),"zenPage.cmdExport();")
	set pCommands($i(tCount)) = $lb("cmdDelete",$$$Text("Delete"),$$$Text("Delete this Text Classifier"),"zenPage.cmdDelete();")
	
	quit $$$OK
}

/// Returned value is used as leaf of breadcrumb
Method %OnGetPageName() As %String
{
	Quit $$$Text("Text Categorization")
}

/// Builds breadcrumb links
Method %GetLocatorLinks(Output pLink) As %Status
{
	Set tPageName = $$$PRODUCT1
	Set pLink($I(pLink)) = $LB(tPageName,..homePage)

	Set tPageName = $$$PRODUCT5
	Set pLink($I(pLink)) = $LB(tPageName,..homePage)
	
	Set tPageName = ..%OnGetPageName()
	Set pLink($I(pLink)) = $LB(tPageName,$ZCVT($className(),"O","URL")_".zen")
	Quit $$$OK
}

Method %OnGetTitle() As %String
{
	if (..definitionClass'="") {
		quit ..definitionClass
	} else {
		quit ..%OnGetPageName()
	}
}

Method LoadDataSourceFields() As %Status [ ZenMethod ]
{
	set tSC = $$$OK
	try {
		
		set tSC = ..OnGetClassifierObject() // ensures ..classifier is set
		quit:$$$ISERR(tSC)
		
		set tParamCount = ..classifier.BuilderParameters.Count()
		for i = 1:1:tParamCount {
			set tParam = ..classifier.BuilderParameters.GetAt(i)
			if (tParam.name="DomainId") {
				set tDomainId = tParam.value
				do ..OnChangeDomain(tDomainId)
			} elseif (tParam.name="TrainingSet") {
				set tTrainingSet = tParam.value
			} elseif (tParam.name="TestSet") {
				set tTestSet = tParam.value
			} elseif (tParam.name="MetadataField") {
				set tMetadataField = tParam.value
			}
		}
		
		set ..%GetComponentById("txtNewClass").value = ..definitionClass
		set ..%GetComponentById("selNewDomain").value = tDomainId
		set ..%GetComponentById("selNewMetadata").value = tMetadataField
		
		// populate training and test set fields
		if $g(tTrainingSet)'="" {
			$$$IKQFILTEROBJECTX(..domain,tTrainingSet,tSC)
			if $isobject(tTrainingSet) {
				if tTrainingSet.%IsA("%iKnow.Filters.SimpleMetadataFilter") {
					
					do ##class(%iKnow.Queries.MetadataAPI).GetFieldInfoById(tTrainingSet.DomainId,tTrainingSet.FieldId,.tFieldInfo)
					set tSC = ..OnChangeFilter(tTrainingSet.DomainId, $g(tFieldInfo("Name")), "")
					quit:$$$ISERR(tSC)
					
					set ..%GetComponentById("selNewFilterField").value = $g(tFieldInfo("Name"))
					set ..%GetComponentById("selNewFilterOperator").disabled = 0
					set ..%GetComponentById("selNewFilterOperator").value = tTrainingSet.FilterOperator
					set ..%GetComponentById("selNewFilterValue").value = tTrainingSet.FilterValue
					
				} elseif tTrainingSet.%IsA("%iKnow.Filters.SqlFilter") {
					
					set ..%GetComponentById("selNewFilterField").value = ":SQL"
					set ..%GetComponentById("selNewFilterOperator").disabled = 1
					set ..%GetComponentById("selNewFilterValue").value = tTrainingSet.SqlQuery
					
				}
			}
		}
		
		if $g(tTestSet)'="" {
			$$$IKQFILTEROBJECTX(..domain,tTestSet,tSC)
			if $isobject(tTestSet) {
				if tTestSet.%IsA("%iKnow.Filters.SimpleMetadataFilter") {
					
					do ##class(%iKnow.Queries.MetadataAPI).GetFieldInfoById(tTestSet.DomainId,tTestSet.FieldId,.tFieldInfo)
					set tSC = ..OnChangeFilter(tTestSet.DomainId, $g(tFieldInfo("Name")), "Test")
					quit:$$$ISERR(tSC)
					
					set ..%GetComponentById("selNewFilterFieldTest").value = $g(tFieldInfo("Name"))
					set ..%GetComponentById("selNewFilterOperatorTest").disabled = 0
					set ..%GetComponentById("selNewFilterOperatorTest").value = tTestSet.FilterOperator
					set ..%GetComponentById("selNewFilterValueTest").value = tTestSet.FilterValue
					
				} elseif tTestSet.%IsA("%iKnow.Filters.SqlFilter") {
					
					set ..%GetComponentById("selNewFilterFieldTest").value = ":SQL"
					set ..%GetComponentById("selNewFilterOperatorTest").disabled = 1
					set ..%GetComponentById("selNewFilterValueTest").value = tTestSet.SqlQuery
					
				}
			}
		}
		
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	if $$$ISERR(tSC) {
		set tMessage = $zconvert($system.Status.GetErrorText(tSC),"O","JS")
		&js<alert('#(tMessage)#');>
	}
	quit tSC
}

Method %OnAfterCreatePage() As %Status
{
	set tSC = $$$OK
	try {
		
		if (..definitionClass'="") {
			set tSC = ..OnGetClassifierObject() // sets ..classifier
			quit:$$$ISERR(tSC)
			
			set tParamCount = ..classifier.BuilderParameters.Count()
			for i = 1:1:tParamCount {
				set tParam = ..classifier.BuilderParameters.GetAt(i)
				if (tParam.name="DomainId") {
					set ..domain = tParam.value
					do ..OnChangeDomain(..domain)
				} elseif (tParam.name="TrainingSet") {
					set (tTrainingSet,..trainingSet) = tParam.value
				} elseif (tParam.name="TestSet") {
					set tTestSet = tParam.value
				} elseif (tParam.name="MetadataField") {
					set tMetadataField = tParam.value
				}
			}
			
			set ..%GetComponentById("grpAll").disabled = 0
			
			set tMethod = ..classifier.ClassificationMethod.method
			if (tMethod'="naiveBayes") && (tMethod'="rules") {
				set ..hideAdvanced = 0
			}
			
			set ..%GetComponentById("txtDomainName").value = $system.iKnow.GetDomainName(..domain)
			
			// populate test set fields in optimizer and new/edit popup
			set tSC = ..LoadDataSourceFields()
			quit:$$$ISERR(tSC)
			
			if $g(tTestSet)'="" {
				$$$IKQFILTEROBJECTX(..domain,tTestSet,tSC)
				if $isobject(tTestSet) {
					if tTestSet.%IsA("%iKnow.Filters.SimpleMetadataFilter") {
						
						do ##class(%iKnow.Queries.MetadataAPI).GetFieldInfoById(tTestSet.DomainId,tTestSet.FieldId,.tFieldInfo)
						set tSC = ..OnChangeFilter(tTestSet.DomainId, $g(tFieldInfo("Name")), "Optimize")
						quit:$$$ISERR(tSC)
					
						set ..%GetComponentById("selOptimizeTestField").value = $g(tFieldInfo("Name"))
						set ..%GetComponentById("selOptimizeTestOperator").disabled = 0
						set ..%GetComponentById("selOptimizeTestOperator").value = tTestSet.FilterOperator
						set ..%GetComponentById("txtOptimizeTestValue").value = tTestSet.FilterValue
						
					} elseif tTestSet.%IsA("%iKnow.Filters.SqlFilter") {
						
						set ..%GetComponentById("selOptimizeTestField").value = ":SQL"
						set ..%GetComponentById("selOptimizeTestOperator").disabled = 1
						set ..%GetComponentById("txtOptimizeTestValue").value = tTestSet.SqlQuery
						
					}
				}
			}
		}
		
		set ..treeID = $i(^IRIS.Temp.TC.BuilderTree)
		
		// populate optimizer task ID to have a single point of reference
		set ..optimizerTask = ##class(%iKnow.Classification.Optimizer).%New().TaskId
		
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit tSC
}

ClientMethod onPopupAction(popupName, action, value) [ Language = javascript ]
{
	if (action != 'ok') return false;
	switch(popupName) {
		case 'iKnow':
			zenPage.gotoPage('_iKnow.Classification.UI.ClassifierBuilder.zen?CLASS=' + encodeURIComponent(value.substring(0,value.length-4)));
			break;
		case 'switchNamespace':
			location.href = zenPage.GetNewURL(value, '_iKnow.Classification.UI.ClassifierBuilder.zen');
			// gotoPage seems to add old $NAMESPACE value...
			//zenPage.gotoPage(zenPage.GetNewURL(value, '_iKnow.Classification.UI.ClassifierBuilder.zen'));
			break;
		default:
			break;
	}
}

ClientMethod confirmLeave() [ Language = javascript ]
{
	if (this.pageModified)
		return confirm($$$Text('This page has changes that have not yet been saved. Continue?'));
	else 
		return true;
}

ClientMethod cmdOpen() [ Language = javascript ]
{
	if (zenPage.confirmLeave()){
		 var parms = {
			MODE: '%iKnow.Classification.Classifier',
		};
		zenLaunchPopupWindow('_iKnow.UI.Dialog.openDomain.zen','iKnow','status,scrollbars,resizable=yes,width=800,height=600',parms);
	}
}

ClientMethod cmdNew() [ Language = javascript ]
{
	if (zenPage.confirmLeave()) {
		zen('modNew').setProperty('groupTitle', 'Create a new classifier');
		zen('btnNewCreate').setProperty('hidden', false);
		zen('btnNewUpdate').setProperty('hidden', true);
		zen('selNewDomain').setProperty('disabled', false);
		zen('txtNewClass').setProperty('disabled', false);
		zen('selNewPopulate').setProperty('disabled', false);
		
		// clear all fields
		zen('txtNewClass').setValue('');
		zen('selNewDomain').setValue('');
		zen('selNewMetadata').setValue(''); 
		zen('selNewMetadata').setProperty('valueList','');
		zen('selNewMetadata').setProperty('displayList','');
		zen('selNewFilterField').setValue(''); 
		zen('selNewFilterField').setProperty('valueList','');
		zen('selNewFilterField').setProperty('displayList','');
		zen('selNewFilterOperator').setValue(''); 
		zen('selNewFilterOperator').setProperty('disabled',true);
		zen('selNewFilterOperator').setProperty('valueList','');
		zen('selNewFilterOperator').setProperty('displayList','');
		zen('selNewFilterValue').setValue('');
		zen('selNewFilterFieldTest').setValue(''); 
		zen('selNewFilterFieldTest').setProperty('valueList','');
		zen('selNewFilterFieldTest').setProperty('displayList','');
		zen('selNewFilterOperatorTest').setValue(''); 
		zen('selNewFilterOperatorTest').setProperty('disabled',true);
		zen('selNewFilterOperatorTest').setProperty('valueList','');
		zen('selNewFilterOperatorTest').setProperty('displayList','');
		zen('selNewFilterValueTest').setValue('');
		
		this._selNewFilterOperatorTestSet = false;
		
		zen('modNew').show();
	}
}

ClientMethod cmdEditDataSource() [ Language = javascript ]
{
	if (zenPage.LoadDataSourceFields()!=1) return;
	zen('modNew').setProperty('groupTitle', 'Update classifier data settings');
	zen('btnNewCreate').setProperty('hidden', true);
	zen('btnNewUpdate').setProperty('hidden', false);
	zen('selNewDomain').setProperty('disabled', true);
	zen('txtNewClass').setProperty('disabled', true);
	zen('selNewPopulate').setProperty('disabled', true);
	zen('modNew').show();
}

ClientMethod cmdBuild() [ Language = javascript ]
{
	if (!zen('json').submitContent('build'))
		alert(zen('json').getError());
}

ClientMethod cmdDelete() [ Language = javascript ]
{
	if (confirm($$$Text('Are you sure you want to delete this Text Classifier?'))) {
		var ok = zenPage.DeleteClassifier()
		if (ok != 'OK') {
			alert($$$Text('Error deleting Text Classifier:')+'\n'+ok.replaceAll('\\',''));
		} else {
			zenPage.gotoPage('_iKnow.Classification.UI.ClassifierBuilder.zen');
		}
	}
}

Method DeleteClassifier() As %Status [ ZenMethod ]
{
	quit:..definitionClass="" $$$OK
	set ok = $SYSTEM.OBJ.Delete(..definitionClass, "-d")
	quit $case(ok, $$$OK:"OK", :$zcvt($SYSTEM.Status.GetErrorText(ok),"O","JS"))
}

ClientMethod cmdSave() [ Language = javascript ]
{
	var sc = zen('txtSaveClass').setValue(zenPage.getProperty('definitionClass'));
	zen('modSave').show();
}

ClientMethod saveAs(classname) [ Language = javascript ]
{
	var sc = zenPage.setProperty('definitionClass', classname);
	zenPage.endModal();
	if (!zen('json').submitContent('save'))
		alert(zen('json').getError());
	else {
		zenPage.gotoPage('_iKnow.Classification.UI.ClassifierBuilder.zen?CLASS=' + encodeURIComponent(classname));
	}
}

ClientMethod cmdTest() [ Language = javascript ]
{
	if (zenPage.confirmLeave()) {
		window.open('_iKnow.Classification.UI.ClassifierTester.zen?CLASS=' + encodeURIComponent(zenPage.getProperty('definitionClass')), '_blank');
	}
}

ClientMethod cmdOptimize() [ Language = javascript ]
{
	if (zen('selMethod').getValue()=='rules') {
		alert($$$Text('Rule-based categorization models currently can\'t be optimized automatically'));
		return;
	}
	if (zenPage.confirmLeave()) {
		zen('txtOptimizeOutput').setValue('');
		zen('modOptimizeInput').setProperty('disabled', false);
		zen('grpOptimizeStep1').setProperty('hidden', false);
		zen('grpOptimizeStep2').setProperty('hidden', true);
		zen('htmlOptimizerTerms').refreshContents();
		
		// derive test set
		var model = zen('json').getContentObject();
		for (var i = 0; i<model.BuilderParameters.length; i++) {
			if (model.BuilderParameters[i].name == 'TestSet') {
				var filter = model.BuilderParameters[i].value.split('|');
				if (filter[0]=='%iKnow.Filters.SimpleMetadataFilter') {
					zen('selOptimizeTestField').setValue(filter[2].substring(1,filter[2].length-1));
					zen('selOptimizeTestOperator').setValue(filter[3].substring(1,filter[3].length-1));
					var value = isNaN(filter[4]) ? filter[4].substring(1,filter[4].length-1) : filter[4];
					zen('txtOptimizeTestValue').setValue(value);
				} else if (filter[0]=='%iKnow.Filters.SqlFilter') {
					zen('selOptimizeTestField').setValue(':SQL');
					zen('selOptimizeTestOperator').setProperty('disabled', true);
					var sql = filter.slice(2,filter.length).join('|');
					zen('txtOptimizeTestValue').setValue(sql);
				}
				break;
			}
		}
		
		zen('modOptimize').show();
	}
}

ClientMethod cmdExport() [ Language = javascript ]
{
	if (zenPage.confirmLeave()) {
		var cls = zen('txtExportClass').getValue();
		if ((cls == null) || (cls == '')) {
			zen('txtExportClass').setValue(zenPage.getProperty('definitionClass')+'.Data');
		}
		zen('modExport').show();
	}
}

ClientMethod refresh() [ Language = javascript ]
{
	zen('tree').refreshContents();
	
	var model = zen('json').getContentObject();
	if (model) {
		zen('txtDescription').setValue(model.description);
		zen('selLocalTermWeights').setValue(model.ClassificationMethod.localTermWeights);
		zen('selTermNormalization').setValue(model.ClassificationMethod.normalization);
		
		var method = model.ClassificationMethod.method;
		zen('selMethod').setValue(method);
		zen('grpProp'+method).setProperty('hidden', false);
		
		if (method=='pmml') {
			zen('txtPropPMML').setValue(zenPage.getProperty('pmml'));
		} else {
			zen('txtPropPMML').setValue('');
		}
		
		if (method=='rules') {
			
			var rules = model.ClassificationMethod.ClassificationRules;
			if (rules == undefined) {
				rules = { _class:'%iKnow.Classification.Definition.ClassificationRules', 
								Rules:new Array(), ruleSelectionMethod:'firstHit' };
				model.ClassificationMethod.ClassificationRules = rules;
			}
			zen('selPropRuleSelection').setValue(rules.ruleSelectionMethod);
			var valueList = new Array(); var displayList = new Array();
			for (var i = 0; i < rules.Rules.length; i++) {
				valueList[i] = i;
				displayList[i] = 'rule #'+(i+1)+': \''+rules.Rules[i].category+'\'';
			}
			sc = zen('selPropRule').setProperty('valueList', valueList.join(','));
			sc = zen('selPropRule').setProperty('displayList', displayList.join(','));
			if (isNaN(zen('selPropRule').getValue())) sc = zen('selPropRule').setValue(0);
			zen('btnPropRuleEdit').setProperty('disabled', valueList.length==0);
			zen('btnPropRuleDrop').setProperty('disabled', valueList.length==0);
			zen('drwRules').renderContents();
			
			// populate AddRule category dropdown
			var valueList = new Array();
			for (var i = 0; i < model.Categories.length; i++) {
				valueList[i] = model.Categories[i].name;
			}
			sc = zen('selPropRuleCat').setProperty('valueList', valueList.join(','));
			
			var valueList = new Array(); var displayList = new Array();
			for (var i = 1; i <= model.TermDictionary.Terms.length; i++) {
				valueList[i] = i;
				displayList[i] = 'term #'+i+': \''+zenPage.getStringForTerm(model, i).replace(',',';')+'\'';
			}
			sc = zen('selPropPredicateTerm').setProperty('valueList', valueList.join(','));
			sc = zen('selPropPredicateTerm').setProperty('displayList', displayList.join(','));
			
		} else {
			zen('selPropRule').setProperty('valueList','');
			zen('selPropRule').setProperty('displayList','');
			zen('drwRules').renderContents();
			zen('selPropRuleCat').setProperty('valueList','');
			zen('selPropPredicateTerm').setProperty('valueList','');
			zen('selPropPredicateTerm').setProperty('displayList','');
		}
	}
	zenPage.refreshButtons();
}

ClientMethod refreshButtons() [ Language = javascript ]
{
	var cls = zenPage.getProperty('definitionClass');
	if ((cls !== '') && (cls != null)) {
		this.enableCommandButton('cmdBuild');
		this.enableCommandButton('cmdSave');
		this.enableCommandButton('cmdOptimize');
		this.enableCommandButton('cmdTest');
		this.enableCommandButton('cmdExport');
		this.enableCommandButton('cmdDelete');
	} else {
		this.disableCommandButton('cmdBuild');
		this.disableCommandButton('cmdSave');
		this.disableCommandButton('cmdOptimize');
		this.disableCommandButton('cmdTest');
		this.disableCommandButton('cmdExport');
		this.disableCommandButton('cmdDelete');
	}
}

ClientMethod updateBackgroundInfo(label, show) [ Language = javascript ]
{
	if ((label!=null) && (label!='')) {
		var sc = zen('lblBgr').setProperty('label', label);
	}
	if ((show!=null) && show) {
		zen('modBgr').show();
	}
}

ClientMethod changeDomain(domain) [ Language = javascript ]
{
	if (zenPage.OnChangeDomain(domain) == 1) {
		zen('selNewMetadata').refreshContents(); 
		zen('selNewFilterField').refreshContents();
		zen('selNewFilterOperator').refreshContents();
		zen('selNewFilterFieldTest').refreshContents();
		zen('selNewFilterOperatorTest').refreshContents();
	}
}

/// called when selNewDomain changes
Method OnChangeDomain(pDomainId As %Integer) As %Status [ ZenMethod ]
{
	set tSC = $$$OK
	try {
		set tSC = ##class(%iKnow.Queries.MetadataAPI).GetFields(.tFields, pDomainId)
		quit:$$$ISERR(tSC)
		set i = "", tValues=""
		for {
			set i = $order(tFields(i), 1, tField)
			quit:i=""
			
			set tValues = tValues _ "," _ $li(tField,2)
		}
		set tValues = $e(tValues,2,*)
		
		set ..%GetComponentById("selNewMetadata").valueList = tValues
		
		set ..%GetComponentById("selNewFilterField").valueList = tValues_",:SQL"
		set ..%GetComponentById("selNewFilterField").displayList = tValues_",SQL"
		set ..%GetComponentById("selNewFilterOperator").disabled = 1
		
		set ..%GetComponentById("selNewFilterFieldTest").valueList = tValues_",:SQL"
		set ..%GetComponentById("selNewFilterFieldTest").displayList = tValues_",SQL"
		set ..%GetComponentById("selNewFilterOperatorTest").disabled = 1
		
		set ..%GetComponentById("selOptimizeTestField").valueList = tValues_",:SQL"
		set ..%GetComponentById("selOptimizeTestField").displayList = tValues_",SQL"
		set ..%GetComponentById("selOptimizeTestOperator").disabled = 1
		
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	if $$$ISERR(tSC) {
		set tMessage = $zconvert($system.Status.GetErrorText(tSC),"O","JS")
		&js<alert('#(tMessage)#');>
	}
	quit tSC
}

ClientMethod changeFilter(domain, field, suffix) [ Language = javascript ]
{
	if (zenPage.OnChangeFilter(domain, field, suffix) == 1) {
		if (suffix == 'Optimize') {
			zen('selOptimizeTestOperator').refreshContents();
		} else {
			zen('selNewFilterOperator'+suffix).refreshContents();
		}
	}
	if ((suffix=='') && (zen('selNewFilterFieldTest').getValue()=='')) {
		zen('selNewFilterFieldTest').setValue(field);
		zenPage.changeFilter(domain, field, 'Test');
	}
}

Method OnChangeFilter(pDomainId As %Integer, pField As %String, pSuffix As %String) As %Status [ ZenMethod ]
{
	set tSC = $$$OK
	try {
		
		set tOpFieldId = $s(pSuffix="Optimize":"selOptimizeTestOperator", 1:"selNewFilterOperator"_pSuffix)
		set selNewFilterOperator = ..%GetComponentById(tOpFieldId)
		if (pField=":SQL") || (pField="") {
			set selNewFilterOperator.valueList = ""
			set selNewFilterOperator.disabled = 1
		} else {
			set tSC = ##class(%iKnow.Queries.MetadataAPI).GetFieldInfo(pDomainId, pField, .tInfo)
			quit:$$$ISERR(tSC)
			set selNewFilterOperator.valueList = tInfo("SupportedOperators")
			set selNewFilterOperator.disabled = 0
		}
		
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	if $$$ISERR(tSC) {
		set tMessage = $zconvert($system.Status.GetErrorText(tSC),"O","JS")
		&js<alert('#(tMessage)#');>
	}
	quit tSC
}

ClientMethod changeFilterOperator(operator) [ Language = javascript ]
{
	var selOperator = zen('selNewFilterOperatorTest');
	if (!this._selNewFilterOperatorTestSet) {
		var invOp = '';
		switch (operator) {
			case '=': invOp = '!='; break;
			case '!=': invOp = '='; break;
			case '>': invOp = '<='; break;
			case '<': invOp = '>='; break;
			case '>=': invOp = '<'; break;
			case '<=': invOp = '>'; break;
			default: 
				invOp = operator; 
				break;
		}
		var supported = selOperator.getProperty('valueList').split(',');
		if (supported.indexOf(invOp)>=0) {
			selOperator.setValue(invOp);
		} else {
			selOperator.setValue(operator);
		}
		this._selNewFilterOperatorTestSet = true; 
	}
}

ClientMethod updateModelProp(prop, value) [ Language = javascript ]
{
	var model = zen('json').getContentObject();
	var propPath = prop.split('.');
	if (propPath.length == 1) {
		model[propPath[0]] = value;
	} else if (propPath.length == 2) {
		model[propPath[0]][propPath[1]] = value;
	} else if (propPath.length == 3) {
		model[propPath[0]][propPath[1]][propPath[2]] = value;
	}
	zen('json').setContentObject(model);
	zenPage.setProperty('pageModified', true);
}

ClientMethod updateMethod(method) [ Language = javascript ]
{
	var model = zen('json').getContentObject();
	var current = model.ClassificationMethod.method;
	
	if ((current == 'pmml') && !confirm($$$Text('Changing the classification method will erase your existing PMML model.')+'\n'+$$$Text('Do you want to continue?'))) {
		zen('selMethod').setValue('pmml');
		return;
	}
	if ((current == 'rules') && !confirm($$$Text('Changing the classification method will erase your existing decision rules.')+'\n'+$$$Text('Do you want to continue?'))) {
		zen('selMethod').setValue('rules');
		return;
	}
	
	model.ClassificationMethod.method = method;
	zen('grpProp'+method).setProperty('hidden', false);
	zen('grpProp'+current).setProperty('hidden', true);
	
	// force update of local term metric for Naive Bayes
	if (method=='naiveBayes') {
		zen('selLocalTermWeights').setValue('binary');
		model.ClassificationMethod.localTermWeights = 'binary';
		zen('selTermNormalization').setValue('none');
		model.ClassificationMethod.normalization = 'none';
	}
	
	// drop CategoryWeights / ClassificationRules / PMML if not appropriate
	if (method!='rules') {
		delete model.ClassificationMethod.ClassificationRules;
	} else {
		model.ClassificationMethod.ClassificationRules = { _class:'%iKnow.Classification.Definition.ClassificationRules', ruleSelectionMethod:'allHits', Rules:[] };
	}
	if (method!='pmml') {
		delete model.ClassificationMethod.PMML;
	}
	if ((method!='naiveBayes') && (method!='cosineSimilarity') && (method!='euclideanDistance') && (method!='linearRegression')) {
		delete model.ClassificationMethod.CategoryTermWeights;
		delete model.ClassificationMethod.CategoryWeights;
	}
	
	var sc = zen('json').setContentObject(model);
	zenPage.setProperty('pageModified', true);
	
	// when changing to rules, suggest auto-generating rules
	if ((method=='rules') && confirm($$$Text('Create default rules?\nThis will save the current model.'))) {
		if (!zen('json').submitContent('save'))
			alert(zen('json').getError());
		else {
			sc = zenPage.GenerateRuleSet();
			sc = zen('json').reloadContents();
		}
	}
	
	zenPage.refresh();
}

Method SetClassname(pClassname As %String) As %String [ ZenMethod ]
{
	if '$zname(pClassname, 4) {
		quit "Invalid class name: '"_pClassname_"'"
	}
	if $$$defClassDefined(pClassname) {
		quit "Class already exists: '"_pClassname_"'"
	}
	set ..definitionClass = pClassname
	quit "OK"
}

ClientMethod updateClassifier() [ Language = javascript ]
{
	var model = zen('json').getContentObject();
	var domain = zen('selNewDomain').getValue();
	
	var metadatafield = zen('selNewMetadata').getValue();
	if ((metadatafield == null) || (metadatafield == '')) {
		alert('Please select a metadata field as the categorization target');
		return;
	}
	
	for (var i = model.BuilderParameters.length-1; i>=0; i--) {
		var param = model.BuilderParameters[i];
		if (param.name=='MetadataField') {
			if (param.value==metadatafield) {
				continue;
			} else {
				if (model.ClassificationMethod.method=='rules') {
					if (confirm('Changing the metadata field will erase any rules defined so far.\nContinue?')) {
						model.ClassificationMethod.ClassificationRules.Rules = [];
					} else {
						return;
					}
				}
				param.name = metadatafield;
				model.Categories = [];
			}
		}
		
		// first get rid of existing training/test filters
		if ((param.name=='TrainingSet') || (param.name=='TestSet')) {
			model.BuilderParameters.splice(i,1);
		}
	}
	
	// restore metadata field
	var cls = '%iKnow.Classification.Definition.BuilderParameter';
	model.BuilderParameters[model.BuilderParameters.length] = { _class:cls, name:'MetadataField', value:metadatafield };
	
	
	// now append new TrainingSet param
	var filterSpec = zen('selNewFilterField').getValue();
	if ((filterSpec != null) && (filterSpec != '')) {
		if (filterSpec == ':SQL') {
			filterSpec = '%iKnow.Filters.SqlFilter|'+domain+'|'+zen('selNewFilterValue').getValue();
		} else {
			filterSpec = '%iKnow.Filters.SimpleMetadataFilter|' + domain + '|"' + filterSpec;
			filterSpec += '"|"'+ zen('selNewFilterOperator').getValue();
			var filterValue = zen('selNewFilterValue').getValue();
			filterSpec += '"|'+ (isNaN(filterValue) ? '"'+filterValue+'"' : filterValue);
		}
		model.BuilderParameters[model.BuilderParameters.length] = { _class:cls, name:'TrainingSet', value:filterSpec };
		
	}
	
	// also update page property (used for filtering term search boxes)
	zenPage.setProperty('trainingSet', filterSpec);
	
	// append new TestSet
	var filterSpec = zen('selNewFilterFieldTest').getValue();
	if ((filterSpec != null) && (filterSpec != '')) {
		if (filterSpec == ':SQL') {
			filterSpec = '%iKnow.Filters.SqlFilter|'+domain+'|'+zen('selNewFilterValueTest').getValue();
		} else {
			filterSpec = '%iKnow.Filters.SimpleMetadataFilter|' + domain + '|"' + filterSpec;
			filterSpec += '"|"'+ zen('selNewFilterOperatorTest').getValue();
			var filterValue = zen('selNewFilterValueTest').getValue();
			filterSpec += '"|'+ (isNaN(filterValue) ? '"'+filterValue+'"' : filterValue);
		}
		model.BuilderParameters[model.BuilderParameters.length] = { _class:cls, name:'TestSet', value:filterSpec };
	}
	
	// save object
	sc = zen('json').setContentObject(model);
	if (!zen('json').submitContent('update')) {
		alert(zen('json').getError());
		return;
	}
	
	zenPage.endModal();
	zenPage.refresh();
}

/// called when btnNewCreate is clicked
ClientMethod createClassifier() [ Language = javascript ]
{
	var classname = zen('txtNewClass').getValue();
	var sc = zenPage.SetClassname(classname);
	if (sc != 'OK') {
		alert(sc);
		return;
	}
	
	var domain = zen('selNewDomain').getValue();
	if ((domain == null) || isNaN(domain)) {
		alert('Please select an iKnow domain');
		return;
	}
	
	var metadatafield = zen('selNewMetadata').getValue();
	if ((metadatafield == null) || (metadatafield == '')) {
		alert('Please select a metadata field as the categorization target');
		return;
	}
	
	// builder parameters
	var pckg = '%iKnow.Classification.Definition.';
	var params = new Array();
	params[params.length] = { _class:pckg+'BuilderParameter', name:'DomainId', value:domain };
	params[params.length] = { _class:pckg+'BuilderParameter', name:'MetadataField', value:metadatafield };
	
	var filterSpec = zen('selNewFilterField').getValue();
	if ((filterSpec != null) && (filterSpec != '')) {
		if (filterSpec == ':SQL') {
			filterSpec = '%iKnow.Filters.SqlFilter|'+domain+'|'+zen('selNewFilterValue').getValue();
		} else {
			filterSpec = '%iKnow.Filters.SimpleMetadataFilter|' + domain + '|"' + filterSpec;
			filterSpec += '"|"'+ zen('selNewFilterOperator').getValue();
			var filterValue = zen('selNewFilterValue').getValue();
			filterSpec += '"|'+ (isNaN(filterValue) ? '"'+filterValue+'"' : filterValue);
		}
		params[params.length] = { _class:pckg+'BuilderParameter', name:'TrainingSet', value:filterSpec };
	}
	
	var filterSpec = zen('selNewFilterFieldTest').getValue();
	if ((filterSpec != null) && (filterSpec != '')) {
		if (filterSpec == ':SQL') {
			filterSpec = '%iKnow.Filters.SqlFilter|'+domain+'|'+zen('selNewFilterValueTest').getValue();
		} else {
			filterSpec = '%iKnow.Filters.SimpleMetadataFilter|' + domain + '|"' + filterSpec;
			filterSpec += '"|"'+ zen('selNewFilterOperatorTest').getValue();
			var filterValue = zen('selNewFilterValueTest').getValue();
			filterSpec += '"|'+ (isNaN(filterValue) ? '"'+filterValue+'"' : filterValue);
		}
		params[params.length] = { _class:pckg+'BuilderParameter', name:'TestSet', value:filterSpec };
	}
	
	var obj = { _class:pckg+'Classifier', 
				builderClass: '%iKnow.Classification.IKnowBuilder', BuilderParameters:params,
				ClassificationMethod: { _class:pckg+'ClassificationMethod', method:'naiveBayes' },
				TermDictionary: { _class:pckg+'TermDictionary', Terms:[] } };
	
	// store new object
	sc = zen('json').setContentObject(obj);
	if (!zen('json').submitContent('saveNew')) {
		alert(zen('json').getError());
		return;
	}
	
	if (classname.indexOf('.') < 0) {
		classname = 'User.'+classname;
	}
	
	var populate = zen('selNewPopulate').getValue();
	if (populate != 'none') {
		sc = zenPage.setProperty('definitionClass', classname);
		sc = zenPage.PopulateTerms(populate, zen('txtNewPopulateN').getValue());
	}
	
	zenPage.gotoPage('_iKnow.Classification.UI.ClassifierBuilder.zen?CLASS=' + encodeURIComponent(classname));
}

ClassMethod SaveClassifierStatic(pDefinitionClass As %String, pXML As %String) As %Status [ Internal ]
{
	set tSC = $$$OK
	try {
		do ..%SetBackgroundMethodStatus("Building...", 0)
		
		kill ^IRIS.Temp.TC.BgrTask($job)
		set ^IRIS.Temp.TC.BgrTask($job, "info", "success") = $$$Text("Classifier built successfully")
		set ^IRIS.Temp.TC.BgrTask($job, "info", "success", "action") = "zenPage.setProperty('pageModified', false); zenPage.endModal();"
		set ^IRIS.Temp.TC.BgrTask($job, "info", "error") = $$$Text("Error building classifier")
		set ^IRIS.Temp.TC.BgrTask($job, "info", "error", "action") = "zenPage.endModal();"
		
		#dim tBuilder As %iKnow.Classification.IKnowBuilder
		set tSC = ..GetBuilderStatic(.tBuilder, pXML)
		quit:$$$ISERR(tSC)
		
		// create class
		set tSC = tBuilder.%CreateClassifierClass(pDefinitionClass, 0, 1, 1)
		quit:$$$ISERR(tSC)
		
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	set ^IRIS.Temp.TC.BgrTask($job, "status") = tSC
	do ..%EndBackgroundMethod()
	quit tSC
}

ClassMethod GetBuilderStatic(Output pBuilder As %iKnow.Classification.IKnowBuilder, pXML As %String) As %Status [ Internal, Private ]
{
	set tSC = $$$OK
	try {
		set tReader = ##class(%XML.Reader).%New()
		set tSC = tReader.OpenString(pXML)
		quit:$$$ISERR(tSC)
		
		do tReader.Correlate("Classifier", "%iKnow.Classification.Definition.Classifier")
		quit:'tReader.Next(.tDefinition, .tSC)
		
		set tSC = ##class(%iKnow.Classification.Builder).%LoadFromModel(tDefinition, .pBuilder)
		quit:$$$ISERR(tSC)
		
		if (pBuilder="") {
			set tSC = %objlasterror
			quit
		}
		
		if ('tDefinition.Categories.Count()) {
			set tParamCount = tDefinition.BuilderParameters.Count()
			for i = 1:1:tParamCount {
				set tParam = tDefinition.BuilderParameters.GetAt(i)
				continue:tParam.name'="MetadataField"
				set tSC = pBuilder.%LoadMetadataCategories(tParam.value)
	 			quit:$$$ISERR(tSC)
	 			quit
			}
			quit:$$$ISERR(tSC)
		}
		
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit tSC
}

Method OnGetClassifierObject(ByRef Params, Output pObject As %RegisteredObject) As %Status
{
	set tSC = $$$OK
	try {
		if $isobject(..classifier) {
			set pObject = ..classifier
		} elseif (..definitionClass="") {
			set pObject = ##class(%iKnow.Classification.Definition.Classifier).%New()
			set pObject.builderClass = "%iKnow.Classification.IKnowBuilder"
			set pObject.ClassificationMethod = ##class(%iKnow.Classification.Definition.ClassificationMethod).%New()
			set pObject.ClassificationMethod.method = "naiveBayes"
			set pObject.TermDictionary = ##class(%iKnow.Classification.Definition.TermDictionary).%New()
			set ..classifier = pObject
		} else {
			set tSC = ##class(%iKnow.Classification.Definition.Classifier).%GetFromDefinition(..definitionClass, .pObject, 0)
			quit:$$$ISERR(tSC)
			
			// convert legacy Term objects
			set tTermCount = pObject.TermDictionary.Terms.Count()
			for i = 1:1:tTermCount {
				set tTerm = pObject.TermDictionary.Terms.GetAt(i)
				continue:tTerm.value=""
				
				if (tTerm.type="entity") {
					set tNewTerm = ##class(%iKnow.Classification.Definition.TermEntity).%New()
					do tNewTerm.Entries.Insert(tTerm.value)
				} elseif (tTerm.type="crc") {
					set tNewTerm = ##class(%iKnow.Classification.Definition.TermCRC).%New()
					set tEntry = ##class(%iKnow.Classification.Definition.TermCRCEntry).%New()
					set tEntry.Master = $piece(tTerm.value,":",1)
					set tEntry.Relation = $piece(tTerm.value,":",2)
					set tEntry.Slave = $piece(tTerm.value,":",3)
					do tNewTerm.Entries.Insert(tEntry)
				} else {
					set tNewTerm = ##class(%iKnow.Classification.Definition.TermCooccurrence).%New()
					set tEntry = ##class(%iKnow.Classification.Definition.TermCoocEntry).%New()
					for j = 1:1:$l(tTerm.value,":") {
						do tEntry.Entities.Insert($piece(tTerm.value,":",j))
					}
					do tNewTerm.Entries.Insert(tEntry)
				}
				set tNewTerm.count = tTerm.count, tNewTerm.negation = tTerm.negation
				do pObject.TermDictionary.Terms.SetAt(tNewTerm, i)
			}
			
			
			set ..classifier = pObject
		}
		
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit tSC
}

Method SubmitClassifier(pCommand As %String, pProvider As %ZEN.Auxiliary.jsonProvider, pSubmitObject As %RegisteredObject, Output pResponseObject As %RegisteredObject) As %Status
{
	set tSC = $$$OK
	try {
		if (pCommand="refresh") {
			set tSC = ..GetAsTree(pSubmitObject, .tTree)
			quit:$$$ISERR(tSC)
			
			kill ^IRIS.Temp.TC.BuilderTree(..treeID)
			merge ^IRIS.Temp.TC.BuilderTree(..treeID) = tTree
			
			quit
		}
		
		// restore PMML object
		if (pSubmitObject.ClassificationMethod.method="pmml") {
			set tSC = ##class(%DeepSee.PMML.Definition.PMML).%FromString(.tPMML, ..pmml)
			quit:$$$ISERR(tSC)
			set pSubmitObject.ClassificationMethod.PMML = tPMML
		}
		
		if (pCommand="saveNew") || (pCommand="update") {
			
			// ensure categories are loaded
			if ('pSubmitObject.Categories.Count()) {
				for i = 1:1:pSubmitObject.BuilderParameters.Count() {
					set tParam = pSubmitObject.BuilderParameters.GetAt(i)
					if tParam.name = "MetadataField" {
						set tMetadataField = tParam.value
						quit
					}
				}
				#dim tBuilder as %iKnow.Classification.IKnowBuilder
				set tSC = ##class(%iKnow.Classification.IKnowBuilder).%LoadFromModel(pSubmitObject, .tBuilder)
				quit:$$$ISERR(tSC)
				set tSC = tBuilder.%LoadMetadataCategories(tMetadataField)
				quit:$$$ISERR(tSC)
				set tSC = tBuilder.%GenerateClassifier(.pSubmitObject, 1, 0)
				quit:$$$ISERR(tSC)
				set pResponseObject = pSubmitObject
			}
			
			if (pCommand="saveNew") {
				set tSC = pSubmitObject.%SaveToClass(..definitionClass, 1, 0, 0)
				set ..pageModified = 0
			} else {
				set ..pageModified = 1
			}
			quit
		}
		
		if (pCommand="save") {
			set tSC = pSubmitObject.%SaveToClass(..definitionClass, 1, 0, 0)
			set ..pageModified = 0
			quit
		}
		
		if (pCommand="build") {
			
			set tSC = pSubmitObject.XMLExportToString(.tXML)
			quit:$$$ISERR(tSC)
			
			// build in background process
			set tSC = ..%RunBackgroundMethod("SaveClassifierStatic", ..definitionClass, tXML)
			quit:$$$ISERR(tSC)
			
			&js<zenPage.updateBackgroundInfo('Saving class...', true);>
			quit
		}
	  
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit tSC
}

Method GetAsTree(pClassifier As %iKnow.Classification.Definition.Classifier, Output pTree) As %Status [ Private ]
{
	set tSC = $$$OK
	try {
		kill pTree
		
		set tTermCount = pClassifier.TermDictionary.Terms.Count()
		for i = 1:1:tTermCount {
			set tTerm = pClassifier.TermDictionary.Terms.GetAt(i)
			set tNode = $i(pTree)
			set pTree(0,"ch",tNode) = ""
			// $LB(caption, value, hasChildren, link, expanded, icon, tooltip, style)
			set tToolTip = ""
			
			if (tTerm.%IsA("%iKnow.Classification.Definition.TermEntity")) {
				set tEntryCount = tTerm.Entries.Count()
				for j = 1:1:tEntryCount {
					set tChild = $i(pTree)
					set tEntry = tTerm.Entries.GetAt(j)
					set pTree(tNode, "ch", tChild) = ""
					set pTree(tChild) = $lb(tEntry, i_":"_j, 0)
					set tToolTip = tToolTip _ $s(tToolTip="":"", ((tEntryCount>1)&&(j=tEntryCount)):" and ", 1:", ") _ "'"_tEntry_"'"
				}
			} elseif (tTerm.%IsA("%iKnow.Classification.Definition.TermCRC")) {
				set tEntryCount = tTerm.Entries.Count()
				for j = 1:1:tEntryCount {
					set tChild = $i(pTree)
					set tEntry = tTerm.Entries.GetAt(j)
					set pTree(tNode, "ch", tChild) = ""
					set tCaption = tEntry.Master_" - "_tEntry.Relation_" - "_tEntry.Slave
					set pTree(tChild) = $lb(tCaption, i_":"_j, 0)
					set tToolTip = tToolTip _ $s(tToolTip="":"", ((tEntryCount>1)&&(j=tEntryCount)):" and ", 1:", ") _ "["_tCaption_"]"
				}
			} elseif (tTerm.%IsA("%iKnow.Classification.Definition.TermCooccurrence")) {
				set tEntryCount = tTerm.Entries.Count()
				for j = 1:1:tEntryCount {
					set tChild = $i(pTree)
					set tEntry = tTerm.Entries.GetAt(j)
					set pTree(tNode, "ch", tChild) = ""
					set tCaption = ""
					for k = 1:1:tEntry.Entities.Count() {
						set tCaption = tCaption _ $s(tCaption="":"", 1:", ") _ tEntry.Entities.GetAt(k)
					}
					set pTree(tChild) = $lb(tCaption, i_":"_j, 0)
					set tToolTip = tToolTip _ $s(tToolTip="":"", ((tEntryCount>1)&&(j=tEntryCount)):" and ", 1:", ") _ "["_tCaption_"]"
				}
			}
			
			set tIcon = $case(tTerm.count, "partialCount":"deepsee/pie_chart_16.png", "partialScore":"deepsee/pie_chart_fav_24.gif", :"deepsee/numeric_field_16.gif")
			set tToolTip = $case(tTerm.count, "partialCount":"Partial matches for", "partialScore":"Combined partial match score for", :"Occurrences of") _ 
							$case(tTerm.type, "entity":"", "crc":" CRC", :" cooccurrence") _
							$s((tTerm.type'="entity")&&(tTerm.Entries.Count()>1):"s", 1:"") _ " " _ tToolTip
			set:tTerm.negation'="undefined" tToolTip = tToolTip_" with negation context '"_tTerm.negation_"'"
			set tStyle = $case(tTerm.negation, "none":"color:DarkGreen;", "no-explicit":"color:Olive;", "explicit":"color:DarkRed;", "implied":"color:OrangeRed;", :"")
			set pTree(tNode) = $lb(tTerm.GetDisplayName(0), i, 1, "", 0, tIcon, tToolTip, tStyle)
		}
		
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit tSC
}

Method OnGetTree(pRoot As %String, Output pTree, ByRef pParms) As %Status
{
	set tSC = $$$OK
	try {
		kill pTree
		
		if $d(^IRIS.Temp.TC.BuilderTree(+..treeID)) {
			merge pTree = ^IRIS.Temp.TC.BuilderTree(..treeID)
			kill ^IRIS.Temp.TC.BuilderTree(..treeID)
			quit
		}
		
		set tSC = ..OnGetClassifierObject(,.tClassifier)
		quit:$$$ISERR(tSC)
		
		set tSC = ..GetAsTree(tClassifier, .pTree)
		quit:$$$ISERR(tSC)
		
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit tSC
}

ClientMethod clickTreeNode(tree) [ Language = javascript ]
{
	var selected = tree.getSelectedIndex();
	if (this._prevSelectedTreeItem == selected) {
		selected = -1;
		tree.selectItem(selected);
	}
	this._prevSelectedTreeItem = selected;
	zen('btnTermEdit').setProperty('disabled', selected==-1);
	zen('btnTermRemove').setProperty('disabled', selected==-1);
}

ClientMethod dragTreeNode(tree, dragData) [ Language = javascript ]
{
	if ((dragData.value == null) || (dragData.value == '')) return;
	
	var classifier = zen('json').getContentObject();
	
	// this may or may not work: 
	// inner destination ID is something like "a_4_56" where 4 is the 0-based position, subnodes included
	var dragTarget = ZLM.getDragInnerDestination().id;
	if (dragTarget == 'tree') return; // no specific target
	var targetIndex = parseInt(dragTarget.split('_')[1]); var to = 0; 
	// derive the "first" index 'to' based on the subnode-included targetIndex
	for (var index=0; index < targetIndex; index++) {
		index += classifier.TermDictionary.Terms[to].Entries.length;
		if (index < targetIndex) to++;
	}
	var termTo = classifier.TermDictionary.Terms[to];
	if (termTo == null) { alert('Invalid drop target: \''+dragTarget+'\''); return; }
	
	if (dragData.sourceComponent.id == 'tree') {
		var from = dragData.value.split(':');
		from[0] = parseInt(from[0])-1;
		var termFrom = classifier.TermDictionary.Terms[parseInt(from[0])];
		if (termFrom == null) { alert('Dragged term is empty'); return; }
		if (termFrom.type != termTo.type) { alert('Incompatible term types'); return; }
		if (termFrom.negation != termTo.negation) { alert('Warning: different negation policies, now using \''+termTo.negation+'\''); }
		if (termFrom.count != termTo.count) { alert('Warning: different count policies, now using \''+termTo.count+'\''); }
		
		if (from.length==1) {
			zenPage.addTermEntries(termFrom.Entries, termTo);
			classifier.TermDictionary.Terms[to] = termTo;
			classifier.TermDictionary.Terms.splice(parseInt(from[0]),1);
			sc = zenPage.updateRuleTerms(classifier, parseInt(from[0]), to);
		} else {
			from[1] = parseInt(from[1])-1;
			zenPage.addTermEntries(termFrom.Entries.slice(from[1],from[1]+1), termTo);
			classifier.TermDictionary.Terms[to] = termTo;
			if (termFrom.Entries.length==1) {
				classifier.TermDictionary.Terms.splice(parseInt(from[0]),1);
				sc = zenPage.updateRuleTerms(classifier, parseInt(from[0]), to);
			} else {
				classifier.TermDictionary.Terms[parseInt(from[0])].Entries.splice(parseInt(from[1]),1);
			}
		}
		zenPage.setProperty('pageModified', true);
	} else {
		
	}
	
	var sc = zen('json').setContentObject(classifier);
	if (!zen('json').submitContent('refresh'))
		alert(zen('json').getError());
	else
		zenPage.refresh();
}

ClientMethod updateRuleTerms(model, removedIndex, toIndex) [ Internal, Language = javascript ]
{
	if (!model.ClassificationMethod.ClassificationRules) return;
	for (var i = 0; i < model.ClassificationMethod.ClassificationRules.Rules.length; i++) {
		var rule = model.ClassificationMethod.ClassificationRules.Rules[i];
		var sc = zenPage.updateRuleTermsPredicate(rule.Predicate, removedIndex, toIndex, rule, -2);
	}
	return true;
}

ClientMethod updateRuleTermsPredicate(predicate, removedIndex, toIndex, parent, parentIdx) [ Internal, Language = javascript ]
{
	if (!predicate) return true;
	var type = predicate._class.substr(42);
	switch (type) {
		case 'NOT':
			return zenPage.updateRuleTermsPredicate(predicate.predicate, removedIndex, toIndex, predicate, -1);
		case 'AND':
		case 'OR':
			for (var i = predicate.predicates.length-1; i >= 0; i--) {
				var sc = zenPage.updateRuleTermsPredicate(predicate.predicates[i], removedIndex, toIndex, predicate, i);
			}
			return sc;
		default:
			// update condition
			// (predicate.term is 1-based, removedIndex and toIndex are 0-based!)
			var term = parseInt(predicate.term)-1;
			if (term == removedIndex) {
				if (toIndex != null) { // replace with new term index
					predicate.term = (toIndex>removedIndex) ? toIndex : toIndex+1;
				} else if (parentIdx == -2) { // rule
					delete parent.Predicate;
				} else if (parentIdx == -1) { // NOT
					delete parent.predicate;
				} else {
					parent.predicates.splice(parentIdx, 1);
				}
			} else if (term > removedIndex) {
				predicate.term = term;
			}
			return true;
	}
}

ClientMethod exploreDelayed(id, string) [ Language = javascript ]
{
	// clear previous timeout
	if (this._exploreTimeout != null) {
		clearTimeout(this._exploreTimeout);
	}
	
	if (zenEvent && ((zenEvent.keyCode==13) || (zenEvent.which==13))) {
		zenPage.explore(id, string);
	} else if ((string != null) && (string.length >= 3)) {
		this._exploreTimeout = setTimeout(function() { zenPage.explore(id, string); }, 1000);
	}
}

ClientMethod explore(id, string) [ Language = javascript ]
{
	// clear previous timeout
	if (this._exploreTimeout != null) {
		clearTimeout(this._exploreTimeout);
	}
	
	var sc = zen('rgr'+id+'Seed').setProperty('value', string);
	if (id == 'Coocs') {
		sc = zen('rgr'+id+'Seed2').setProperty('value', string);
	}
	sc = zen('rgr'+id+'Page').setProperty('value', 1);
	zen('rgr'+id).refreshContents();
	zen('btn'+id+'Next').setProperty('disabled', false);
}

ClientMethod exploreNext(id, shift) [ Language = javascript ]
{
	var page = parseInt(zen('rgr'+id+'Page').value)+shift;
	if (page <= 0) { page = 1; }
	var sc = zen('rgr'+id+'Page').setProperty('value', page);
	zen('rgr'+id).refreshContents();
	zen('btn'+id+'Prev').setProperty('disabled', page==1);
}

ClientMethod exploreTop(metric) [ Language = javascript ]
{
	var sc = zen('rgrTop').setProperty('queryName', 'GetTop'+metric.toUpperCase());
	sc = zen('rgrTopPage').setProperty('value', 1);
	sc = zen('lblTopMetric').setProperty('label', '#(%query.'+metric+')#');
	zen('rgrTop').refreshContents();
}

ClientMethod exploreSQL(sql) [ Language = javascript ]
{
	var sc = zenPage.UpdateSQL(sql);
	if (sc != 'OK') {
		alert(sc);
	} else {
		zen('rgrSQL').refreshContents();
	}
}

Method UpdateSQL(pSQL As %String) As %String [ ZenMethod ]
{
	// first test!
	set tStatement = ##class(%SQL.Statement).%New()
	set tSC = tStatement.%Prepare(pSQL)
	if $$$ISERR(tSC) {
		quit $system.Status.GetErrorText(tSC)
	} else {
		set ..%GetComponentById("rgrSQL").sql = pSQL
		set tFirstColumn = tStatement.%Metadata.columns.GetAt(1).colName
		set ..%GetComponentById("htmlSQLCheckbox").seed = "SQL:#(%query."_tFirstColumn_")#"
		set ..%GetComponentById("lblSQLValue").label = "#(%query."_tFirstColumn_")#"
		quit "OK"
	}
}

Method DrawCheckbox(pSeed As %String) As %Status
{
	set tID = $piece(pSeed,":",1), tValue = $piece(pSeed,":",2,*)
	&html<<input name="chk#(tID)#" type="checkbox" onclick="zenPage.toggleElement('#(tID)#','#(tValue)#');" title="#(tValue)#" />>
	quit $$$OK
}

ClientMethod toggleElement(id, value) [ Language = javascript ]
{
	value = value.toLowerCase();
	var currentValues = zen('hid'+id).getValue();
	if ((currentValues == '') || (currentValues == null)) {
		currentValues = value;
	} else {
		currentValues = currentValues.split(':');
		var currentIndex = currentValues.indexOf(value);
		if (currentIndex == -1) {
			currentValues[currentValues.length] = value;
		} else {
			currentValues.splice(currentIndex,1);
		}
		currentValues = currentValues.join(':');
	}
	zen('hid'+id).setValue(currentValues);
}

ClientMethod addElements(id, type, individual) [ Language = javascript ]
{
	var string = zen('hid'+id).getValue();
	if (string == '') {
		string = zen('txt'+id).getValue();
	}
	
	if (zenPage.add(string, type, individual)) {
		
		// clear queue and uncheck all checkboxes
		zen('hid'+id).setValue('');
		var checkboxes = document.getElementsByName('chk'+id);
		for (var i = 0; i<checkboxes.length; i++) {
			checkboxes[i].checked = false;
		}
	}
}

ClientMethod addTermEntries(entries, term) [ Internal, Language = javascript, Private ]
{
	// add entries one by one
	for (var i = 0; i < entries.length; i++) {
		
		// check if not in the list yet
		var inList = false;
		for (var j = 0; j < term.Entries.length; j++) {
			if (term.type=='entity') {
				inList = (entries[i] == term.Entries[j]);
			} else if (term.type=='crc') {
				inList = ((entries[i].Master == term.Entries[j].Master) && (entries[i].Relation == term.Entries[j].Relation) && (entries[i].Slave == term.Entries[j].Slave));
			} else if (term.type=='cooccurrence') {
				if (entries[i].Entities.length == term.Entries[j].Entities.length) {
					var entCount = 0;
					for (var k = 0; k < entries[i].Entities.length; k++) {
						var entity = entries[i].Entities[k];
						if (term.Entries[j].Entities.indexOf(entity) >= 0) {
							entCount++;
						}
					}
					inList = (entCount == entries[i].Entities.length);
				}
			}
			if (inList) break;
		}
		if (!inList) {
			term.Entries[term.Entries.length] = entries[i];
		}
	}
}

ClientMethod termInArray(termArray, term) [ Internal, Language = javascript ]
{
	var index = -1;
	for (var i = 0; i < termArray.length; i++) {
		var t = termArray[i];
		if (t.type != term.type) continue;
		if (t.negation != term.negation) continue;
		if (t.count != term.count) continue;
		if (t.Entries.length != term.Entries.length) continue;
		var identical = true;
		for (var j = 0; j < t.Entries.length; j++) {
			switch (t.type) {
				case 'entity':
					identical = (t.Entries[j]==term.Entries[j]);
					break;
				case 'crc':
					identical = ((t.Entries[j].Master==term.Entries[j].Master) && 
								 (t.Entries[j].Relation==term.Entries[j].Relation) && 
								 (t.Entries[j].Slave==term.Entries[j].Slave))
					break;
				case 'cooccurrence':
					for (var k = 0; k < t.Entries[j].Entities.length; k++) {
						if (term.Entries[j].Entities.indexOf(t.Entries[j].Entities[k])<0) {
							identical = false;
							break;
						}
					}
					break;
			}
			if (!identical) break;
		}
		if (identical) { index = i; break; }
	}
	return index;
}

ClientMethod add(string, type, individual) [ Language = javascript ]
{
	var strings = string.split(':');
	var newEntries = new Array();
	switch (type) {
		case 'crc': 
			cls = '%iKnow.Classification.Definition.TermCRC'; 
			for (var i = 0; i<strings.length; i++) {
				entry = { _class:'%iKnow.Classification.Definition.TermCRCEntry' };
				var mrs = strings[i].split(',');
				entry.Master = zenTrim(mrs[0]);
				entry.Relation = zenTrim(mrs[1]);
				entry.Slave = zenTrim(mrs[2]);
				newEntries[newEntries.length] = entry;
			}
			break;
		case 'cooccurrence': 
			cls = '%iKnow.Classification.Definition.TermCooccurrence'; 
			for (var i = 0; i<strings.length; i++) {
				entry = { _class:'%iKnow.Classification.Definition.TermCoocEntry' };
				entry.Entities = strings[i].split(',');
				newEntries[newEntries.length] = entry;
			}
			break;
		default: 
			cls = '%iKnow.Classification.Definition.TermEntity'; 
			newEntries = strings;
			break;
	}
	
	var classifier = zen('json').getContentObject();
	var dupCount = 0;
	var isModified = false;
	
	if (individual) {
		
		// add as individual terms
		for (var i = 0; i<newEntries.length; i++) {
			var term = { _class:cls, type:type, Entries:[newEntries[i]],
							negation:zen('selTermNegation').getValue(),
							count:zen('selTermCount').getValue() };
			if (zenPage.termInArray(classifier.TermDictionary.Terms, term) < 0)
				classifier.TermDictionary.Terms[classifier.TermDictionary.Terms.length] = term;
			else
				dupCount++;
		}
		isModified = (dupCount < newEntries.length);
		
	} else {
		
		// append or add as a single term
		var appendTo = zen('tree').getValue();
		if ((appendTo==null) || (appendTo=='')) {
			
			var term = { _class:cls, type:type, Entries:newEntries,
							negation:zen('selTermNegation').getValue(),
							count:zen('selTermCount').getValue() };
			if (zenPage.termInArray(classifier.TermDictionary.Terms, term) < 0) {
				classifier.TermDictionary.Terms[classifier.TermDictionary.Terms.length] = term;
				isModified = true;
			} else {
				dupCount++;
			}
			
		} else {
			
			appendTo = parseInt(appendTo.split(':')[0])-1;
			var term = classifier.TermDictionary.Terms[appendTo];
			
			// check if the same type as existing entries
			if (term.Entries.length>0) {
				if (((type == 'entity') && (term.Entries[0].length == undefined)) 
					 || ((type == 'crc') && (term.Entries[0].Relation == undefined))
					 || ((type == 'cooccurrence') && (term.Entries[0].Entities == undefined))) {
					alert('Incompatible term types');
					return false;
				}
			}
			
			zenPage.addTermEntries(newEntries, term, type);
			isModified = true;
		}
	}
	
	if (dupCount  > 0) {
		alert($$$Text('Some of these terms were skipped as they were already part of the model.'));
	}
	
	if (isModified) {
		var sc = zen('json').setContentObject(classifier);
		zenPage.setProperty('pageModified', true);
		
		if (!zen('json').submitContent('refresh')) {
			alert(zen('json').getError());
			return false;
		} else {
			zenPage.refresh();
			return true;
		}
	}
}

ClientMethod showEditTerm() [ Language = javascript ]
{
	var termIndex = zen('tree').getValue().split(':')[0];
	if (termIndex == '') return;
	termIndex = parseInt(termIndex)-1;
	
	var model = zen('json').getContentObject();
	var term = model.TermDictionary.Terms[termIndex];
	
	zen('modEditTerm').setProperty('groupTitle', 'Properties for term \''+zenPage.getStringForTerm(model, termIndex)+'\'');
	zen('selEditTermNegation').setValue(term.negation);
	zen('selEditTermCount').setValue(term.count);
	
	zen('modEditTerm').show();
}

ClientMethod editTerm() [ Language = javascript ]
{
	var termIndex = zen('tree').getValue().split(':')[0];
	if (termIndex == '') return;
	termIndex = parseInt(termIndex)-1;
	
	var model = zen('json').getContentObject();
	model.TermDictionary.Terms[termIndex].negation = zen('selEditTermNegation').getValue();
	model.TermDictionary.Terms[termIndex].count = zen('selEditTermCount').getValue();
	
	var sc = zen('json').setContentObject(model);
	if (!zen('json').submitContent('refresh')) {
		alert(zen('json').getError());
	} else {
		zenPage.refresh();
		zenPage.endModal();
		zenPage.setProperty('pageModified', true);
	}
}

ClientMethod removeTerm(termPos) [ Language = javascript ]
{
	if ((termPos == null) || (zenTrim(termPos) == '')) return;
	termPos = termPos.split(':');
	
	var classifier = zen('json').getContentObject();
	var termIdx = parseInt(termPos[0])-1;
	if (termPos.length == 1) {
		// remove whole term
		classifier.TermDictionary.Terms.splice(termIdx, 1);
		sc = zenPage.updateRuleTerms(classifier, termIdx);
	} else {
		// remove term entry
		var term = classifier.TermDictionary.Terms[termIdx];
		if (term == null) return;
		if (term.Entries.length == 1) {
			classifier.TermDictionary.Terms.splice(termIdx, 1);
			sc = zenPage.updateRuleTerms(classifier, termIdx);
		} else {
			term.Entries.splice(parseInt(termPos[1])-1, 1);
		}
	}
	
	zenPage.setProperty('pageModified', true);
		
	var sc = zen('json').setContentObject(classifier);
	
	if (!zen('json').submitContent('refresh')) {
		alert(zen('json').getError());
	} else {
		zenPage.refresh();
	}
}

XData Style
{
<style type="text/css">

ul.explore {
	font-size: 10px;
}

.vtLabelLeft, .hzLabelLeft {
	width: 130px;
	padding-right: 10px;
}

.zenLabel {
	margin-right: 8px;
}

.tabGroupBody {
	padding: 5px;
	min-height: 300px;
}

.modalGroupTitle td {
	font-size: 1em;
}
.modalGroupBody {
	background: rgb(242, 241, 236);
}

.lblTerms {
	font-size: 12px;
}

.rgrResults {
	height: 300px;
}

img.btnAdvancedMode {
	width: 25px;
	height: 25px;
	cursor: pointer;
}

</style>
}

ClassMethod %OnFinishBackgroundTask(pTaskID As %String)
{
	// first show any remaining output
	do ..%ShowBackgroundTaskOutput(pTaskID)
	
	merge tBgrInfo = ^IRIS.Temp.TC.BgrTask(pTaskID)
	set tSC = $g(tBgrInfo("status"), $$$ERROR($$$GeneralError, "No status information for background job"))
	if $$$ISERR(tSC) {
		set tAlert = $g(tBgrInfo("info", "error"), $$$Text("Error running background job"))
		set tAlert = tAlert _ ":\n" _ $zconvert($system.Status.GetErrorText(tSC),"O","JS")
		if $d(tBgrInfo("info", "error", "action"), tAction) {
			&js<#(tAction)#>
		}
	} else {
		set tAlert = $g(tBgrInfo("info", "success"))
		if (tAlert'="") && $d(tBgrInfo("track", "done"), tDone) {
			set tAlert = tAlert_"\nProcessed "_tDone_" records"
		}
		if $d(tBgrInfo("info", "success", "action"), tAction) {
			&js<#(tAction)#>
		}
	}
	if (tAlert'="") {
		&js<alert('#(tAlert)#');>
	}
	kill ^IRIS.Temp.TC.BgrTask(pTaskID)
}

ClassMethod %OnMonitorBackgroundTask(pTaskID As %String, pStatus As %String, pPercentComplete As %Float)
{
	merge tInfo = ^IRIS.Temp.TC.BgrTask(pTaskID, "track")
	if $data(tStatus) {
		if $d(tStatus("total"), tTotal) {
			set pPercentComplete = $g(tStatus("done")) / tTotal
			set tPercentCompleteStr = $zconvert("Running: "_$fnumber(pPercentComplete*100, "", 2)_" % processed","O","JS")
		} else {
			set tPercentCompleteStr = $zconvert("Running: "_$g(tStatus("done"),0)_" rows processed","O","JS")
		}
		&js<zen('lblBgr').setValue('#(tPercentCompleteStr)#');>
	}
	do ..%ShowBackgroundTaskOutput(pTaskID)
}

ClassMethod %ShowBackgroundTaskOutput(pTaskID As %String)
{
	merge tOutput = ^IRIS.Temp.TC.BgrTask(pTaskID, "output")
	if $data(tOutput) && $data(^IRIS.Temp.TC.BgrTask(pTaskID, "output", "component"), tComponentID) {
		set tAsString = ""
		for i = 1:1:$g(tOutput) {
			set tAsString = tAsString _ $s(tAsString="":"", 1:"\n") _ $zconvert(tOutput(i),"O","JS")
		}
		&js<var txtArea = zen('#(tComponentID)#'); 
			txtArea.setValue('#(tAsString)#');
			txtArea.scrollTop = txtArea.scrollHeight; >
	}
}

Method Export(pClassname As %String, pOverwrite As %Boolean) As %Status [ ZenMethod ]
{
	set tSC = $$$OK
	try {
		set tSC = ..%RunBackgroundMethod("ExportStatic", ..definitionClass, pClassname, pOverwrite)
		quit:$$$ISERR(tSC)
		
		&js<zenPage.updateBackgroundInfo('Exporting data...', true);>
		
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	if $$$ISERR(tSC) {
		set tMessage = $zconvert($system.Status.GetErrorText(tSC),"O","JS")
		&js<alert('#(tMessage)#');>
	}
	quit tSC
}

ClassMethod ExportStatic(pDefinitionClass As %String, pDataClass As %String, pOverwrite As %Boolean) As %Status [ Internal ]
{
	set tSC = $$$OK
	try {
		do ..%SetBackgroundMethodStatus("Exporting...", 0)
		
		kill ^IRIS.Temp.TC.BgrTask($job)
		set ^IRIS.Temp.TC.BgrTask($job, "info", "success") = $$$Text("Data export complete")
		set ^IRIS.Temp.TC.BgrTask($job, "info", "success", "action") = "zenPage.endModal();"
		set ^IRIS.Temp.TC.BgrTask($job, "info", "error") = $$$Text("Error exporting data")
		set ^IRIS.Temp.TC.BgrTask($job, "info", "error", "action") = "zenPage.endModal();"
		
		#dim tBuilder As %iKnow.Classification.IKnowBuilder
		set tSC = ##class(%iKnow.Classification.Builder).%LoadFromDefinition(pDefinitionClass, .tBuilder)
		quit:$$$ISERR(tSC)
		
		set tSC = tBuilder.%ExportDataTable(pDataClass, pOverwrite, 0, 1)
		quit:$$$ISERR(tSC)
		
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	set ^IRIS.Temp.TC.BgrTask($job, "status") = tSC
	do ..%EndBackgroundMethod()
	quit tSC
}

ClientMethod onloadHandler() [ Language = javascript ]
{
	this.invokeSuper('onloadHandler');		// DTB845

	zenPage.enableAutoRefresh = true;
	
	zenPage.refresh();
}

/// Get the title string to add to the locator row.
/// This should be implemented in a subclass.
ClientMethod getPageTitle() As %String [ Language = javascript ]
{
	return this.definitionClass;
}

Method ExecuteResultSet(pRS As %Library.ResultSet, ByRef tSC As %Status, pInfo As %ZEN.Auxiliary.QueryInfo) As %Boolean
{
	set tSC = $$$OK
	merge p = pInfo.parms
	set:'p(1) p(1) = ..domain
	quit:'p(1) 1
	
	set p = $o(p(""),-1)
	set tSC = pRS.Execute(p...)
	
	quit 1
}

ClientMethod onunloadHandler() [ Language = javascript ]
{
	if (this.pageModified)
		return $$$Text('This page has changes that have not yet been saved. Continue?');
	
	zenPage.OnUnload();
}

/// Cleanup method
Method OnUnload() As %Status [ Internal, ZenMethod ]
{
	set tSC = $$$OK
	try {
		kill ^IRIS.Temp.TC.BuilderTree(+..treeID)
		
		if (..optimizerTask) {
			set tOptimizer = ##class(%iKnow.Classification.Optimizer).%New(..optimizerTask, 1)
			set tSC = tOptimizer.Cleanup()
			quit:$$$ISERR(tSC)
		}
		
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit tSC
}

ClientMethod startOptimizer() [ Language = javascript ]
{
	zen('modOptimizeInput').setProperty('disabled', true); // TODO: refine?
	zenPage.Optimize(zen('txtOptimizeMetric').getValue(), zen('txtOptimizeSteps').getValue(), zen('txtOptimizeRemoveRatio').getValue());
}

Method Optimize(pMetric As %String, pSteps As %Integer, pRemoveRatio As %Double) As %Status [ ZenMethod ]
{
	set tSC = $$$OK
	try {
		
		set tSC = ..%RunBackgroundMethod("OptimizeStatic", ..definitionClass, pMetric, pSteps, pRemoveRatio, ..optimizerTask)
		quit:$$$ISERR(tSC)
		
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	if $$$ISERR(tSC) {
		set tMessage = $zconvert($system.Status.GetErrorText(tSC),"O","JS")
		&js<alert('#(tMessage)#');>
	}
	quit tSC
}

ClassMethod OptimizeStatic(pDefinitionClass As %String, pMetric As %String, pSteps As %Integer, pRemoveRatio As %Double, pOptimizerTaskId As %Integer) As %Status [ Internal ]
{
	set tSC = $$$OK
	try {
		do ..%SetBackgroundMethodStatus("Optimizing", 0)
		
		kill ^IRIS.Temp.TC.BgrTask($job)
		set ^IRIS.Temp.TC.BgrTask($job, "output", "component") = "txtOptimizeOutput"
		set ^IRIS.Temp.TC.BgrTask($job, "info", "success") = $$$Text("Optimization process complete")
		set ^IRIS.Temp.TC.BgrTask($job, "info", "success", "action") = "zenPage.refresh(); zen('modOptimizeInput').setProperty('disabled', false);"
		set ^IRIS.Temp.TC.BgrTask($job, "info", "error") = $$$Text("Error running optimization process")
		
		#dim tBuilder As %iKnow.Classification.IKnowBuilder
		set tSC = ##class(%iKnow.Classification.Builder).%LoadFromDefinition(pDefinitionClass, .tBuilder)
		quit:$$$ISERR(tSC)
		
		// configure optimizer
		set tOptimizer = ##class(%iKnow.Classification.Optimizer).%New(pOptimizerTaskId, 0)
		set tOptimizer.Builder = tBuilder  // sets domain ID and metadata field
		set tOptimizer.ScoreMetric = pMetric
		set tOptimizer.RemoveStepRatio = pRemoveRatio
		set tOptimizer.Verbose = $name(^IRIS.Temp.TC.BgrTask($job, "output"))
				
		set tSC = tOptimizer.Optimize(pSteps)
		quit:$$$ISERR(tSC)
		
		set tSC = tOptimizer.SaveClassifier(pDefinitionClass, 1)
		quit:$$$ISERR(tSC)
		
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	set ^IRIS.Temp.TC.BgrTask($job, "status") = tSC
	do ..%EndBackgroundMethod()
	quit tSC
}

ClientMethod editFallback(ruleIndex) [ Language = javascript ]
{
	if (!confirm($$$Text("Replace fallback rule with predicate?"))) return;
	
	var model = zen('json').getContentObject();
	var predicate = { _class:'%iKnow.Classification.Definition.Predicate', term: 1, operator: 'greaterThan', value: 0 };
	model.ClassificationMethod.ClassificationRules.Rules[ruleIndex].Predicate = predicate;
	
	var sc = zen('json').setContentObject(model);
	zenPage.refresh();
	zenPage.setProperty('pageModified', true);
}

ClientMethod renderRule(ruleIndex) [ Language = javascript ]
{
	var svg = zen('svgRules');
	if (svg.svgGroup) {
		for ( var child = svg.svgGroup.firstChild; child != null ; child = svg.svgGroup.firstChild ) {
			svg.svgGroup.removeChild(child);
		}
	}
	
	var rules = zen('json').getContentObject().ClassificationMethod.ClassificationRules;
	if (rules == null) return;
	
	var selectedRule = rules.Rules[parseInt(ruleIndex)];
	if (selectedRule == undefined) return;
	
	// generate node list
	delete this._ruleNodes;
	this._ruleNodes = new Array();
	this._currentY = 10;
	if (selectedRule.Predicate) {
		var root = zenPage.generateRuleNodes(svg, selectedRule.Predicate, 0, 10, ruleIndex);
	} else {
		// this is a fallback rule!
		var NODEHEIGHT = 20;
		var NODEWIDTH = 40;
		var LEAFWIDTH = 120;
		var BOXRADIUS = 3;
	
		var group = svg.document.createElementNS(SVGNS,'svg');
		svg.svgGroup.appendChild(group);
		group.setAttribute('id', 'op0');
		group.setAttribute('overflow', 'visible');
		group.setAttribute('x', 10);
		group.setAttribute('y', 10)
		group.setAttribute('class', 'tcRuleFallback');
		
		var rect = svg.document.createElementNS(SVGNS,'rect');
		group.appendChild(rect);
		rect.setAttribute('rx', BOXRADIUS);
		rect.setAttribute('height', NODEHEIGHT);
		rect.setAttribute('class', 'tcRuleRect');
		rect.setAttribute('onclick', 'zenPage.editFallback('+ruleIndex+');');
		
		var text = svg.document.createElementNS(SVGNS,'text');
		group.appendChild(text);
		text.setAttribute('y', NODEHEIGHT*0.75);
		text.setAttribute('x', 5);
		text.setAttribute('class', 'tcRuleText');
		text.setAttribute('onclick', 'zenPage.editFallback('+ruleIndex+');');
		
		text.appendChild(svg.document.createTextNode('fallback rule for "'+selectedRule.category+'"'));
		rect.setAttribute('width', zenGetBBox(text).width+9);
	
	}
	
	// resize ownerDraw
	var maxX = 0; var maxY = 0;
	for (var i = 0; i<this._ruleNodes.length; i++) {
		var node = this._ruleNodes[i];
		maxX = Math.max(maxX, (node.x + node.width));
		maxY = Math.max(maxY, (node.y + node.height));
	}
	zen('drwRules').setProperty('width', maxX+10);
	zen('drwRules').setProperty('height', maxY+10);
}

ClientMethod generateRuleNodes(svg, pred, level, x, predicateId) [ Language = javascript ]
{
	var NODEHEIGHT = 20;
	var NODEWIDTH = 40;
	var LEAFWIDTH = 120;
	var XSPACE = 20;
	var YSPACE = 20;
	var BOXRADIUS = 3;
	
	if (pred == undefined) return;
	
	var node = { level: level, id:this._ruleNodes.length };
	this._ruleNodes[node.id] = node;
	node.maxChildCount = 0;
	node.children = new Array();
	node.height = NODEHEIGHT;
	node.x = x;
	
	var group = svg.document.createElementNS(SVGNS,'svg');
	svg.svgGroup.appendChild(group);
	group.setAttribute('id', 'op'+node.id);
	group.setAttribute('overflow', 'visible');
	group.setAttribute('x', node.x);
	
	var rect = svg.document.createElementNS(SVGNS,'rect');
	group.appendChild(rect);
	rect.setAttribute('rx', BOXRADIUS);
	rect.setAttribute('class', 'tcRuleRect');
	rect.setAttribute('onclick', 'zenPage.showEditPredicate(\''+predicateId+'\', true);')
	
	var text = svg.document.createElementNS(SVGNS,'text');
	group.appendChild(text);
	text.setAttribute('y', node.height*0.75);
	text.setAttribute('x', 5);
	text.setAttribute('class', 'tcRuleText');
	text.setAttribute('onclick', 'zenPage.showEditPredicate(\''+predicateId+'\', true);')
	
	node.type = pred._class.substr(42);
	if ((node.type == 'AND') || (node.type == 'OR')) {
	
		//node.width = NODEWIDTH;
		node.string = node.type;
		text.appendChild(svg.document.createTextNode(node.string));
		node.width = zenGetBBox(text).width+9;
		node.class = 'tcRule'+node.type;
		var y = 0;
		for (var i = 0; i < pred.predicates.length; i++) {
			node.children[i] = zenPage.generateRuleNodes(svg, pred.predicates[i], level+1, x+node.width+XSPACE, predicateId + ':' + i);
			node.maxChildCount += node.children[i].maxChildCount;
			y += parseInt(this._ruleNodes[node.children[i]].y);
		}
		node.y = (y==0) ? 10 : (y / node.children.length);
	
	} else if (node.type == 'NOT') {
	
		//node.width = NODEWIDTH;
		node.string = node.type;
		text.appendChild(svg.document.createTextNode(node.string));
		node.width = zenGetBBox(text).width+9;
		node.class = 'tcRule'+node.type;
		node.children[0] = zenPage.generateRuleNodes(svg, pred.predicate, level+1, x+node.width+XSPACE, predicateId + ':' + i);
		node.maxChildCount = node.children[0].maxChildCount;
		node.y = this._ruleNodes[node.children[0]].y;
		
	} else {
	
		node.width = LEAFWIDTH;
		node.class = 'tcRulePredicate';
		if (pred.operator == "equal") {
			var op = "=";
		} else if (pred.operator == "notEqual") {
			var op = "!=";
		} else if (pred.operator == "lessThan") {
			var op = "<";
		} else if (pred.operator == "lessOrEqual") {
			var op = "<=";
		} else if (pred.operator == "greaterThan") {
			var op = ">";
		} else if (pred.operator == "greaterOrEqual") {
			var op = ">=";
		}
		node.string = zenPage.getStringForTerm(zen('json').getContentObject(), pred.term) + ' ' + op + ' ' + pred.value;
		text.appendChild(svg.document.createTextNode(node.string));
		node.width = zenGetBBox(text).width+9;
	
		node.maxChildCount = 1;
		node.y = this._currentY;
		this._currentY += YSPACE+NODEHEIGHT;
	}
	group.setAttribute('y', node.y);
	group.setAttribute('class', node.class);
	
	rect.setAttribute('width', node.width);
	rect.setAttribute('height', node.height);
	
	for (var i = 0; i < node.children.length; i++) {
		zenPage.drawConnector(svg, node, this._ruleNodes[node.children[i]]);
	}
	
	return node.id;
}

ClientMethod getStringForTerm(model, termIndex) [ Language = javascript ]
{
	var term = model.TermDictionary.Terms[parseInt(termIndex)-1];
	if (term == undefined) {
		return '[undefined]';
	}
	if (term.Entries[0].length != undefined) {
		var str = term.Entries[0];
	} else if (term.Entries[0].Relation != undefined) {
		var str = zenTrim(term.Entries[0].Master+' '+term.Entries[0].Relation+' '+term.Entries[0].Slave);
	} else {
		var str = term.Entries[0].Entities.join(',');
	}
	if (term.Entries.length > 1) { str += ' *'; }
	return str;
}

ClientMethod drawConnector(svg, fromNode, toNode) [ Language = javascript ]
{
	var XSPACE = 20;
	var CONNRADIUS = 4;
	
	var line = svg.document.createElementNS(SVGNS,'path');
	svg.svgGroup.appendChild(line);
	var from = { x:fromNode.x+fromNode.width, y:fromNode.y+(fromNode.height/2) };
	var to = { x:toNode.x, y:toNode.y+(toNode.height/2) };
	var path = "M"+from+" ";
	if (from.y == to.y) {
		var path = 'M'+from.x+','+from.y+' L'+to.x+','+to.y;
	} else if (from.y < to.y) {
		var hopX = to.x - XSPACE/2;
		var path = 'M'+from.x+','+from.y+' L'+(hopX-CONNRADIUS)+','+from.y;
		path += ' A'+CONNRADIUS+','+CONNRADIUS+' 0 0,1 '+ hopX+','+(from.y+CONNRADIUS);
		path += ' L'+hopX+','+(to.y-CONNRADIUS);
		path += ' A'+CONNRADIUS+','+CONNRADIUS+' 0 0,0 '+ (hopX+CONNRADIUS)+','+to.y;
		path += ' L'+ to.x+','+to.y;
	} else {
		var hopX = to.x - XSPACE/2;
		var path = 'M'+from.x+','+from.y+' L'+(hopX-CONNRADIUS)+','+from.y;
		path += ' A'+CONNRADIUS+','+CONNRADIUS+' 0 0,0 '+ hopX+','+(from.y-CONNRADIUS);
		path += ' L'+hopX+','+(to.y+CONNRADIUS);
		path += ' A'+CONNRADIUS+','+CONNRADIUS+' 0 0,1 '+ (hopX+CONNRADIUS)+','+to.y;
		path += ' L'+ to.x+','+to.y;
	}
	line.setAttribute('d', path);
	line.setAttribute('class', 'tcConnector'+fromNode.type);
}

ClientMethod dropRule(ruleIndex) [ Language = javascript ]
{
	var classifier = zen('json').getContentObject();
	if (classifier == null) return;
	
	classifier.ClassificationMethod.ClassificationRules.Rules.splice(parseInt(ruleIndex),1);
	zen('json').setContentObject(classifier);
	zenPage.refresh();
	zenPage.setProperty('pageModified', true);
}

ClientMethod showEditRule(ruleIndex) [ Language = javascript ]
{
	ruleIndex = parseInt(ruleIndex);
	if (ruleIndex < 0) {
		zen('hidPropRuleIndex').setValue(-1);
		zen('txtPropRuleScore').setValue(1);
		zen('chkPropRuleFallback').setProperty('hidden', false);
		zen('chkPropRuleFallback').setValue(false);
	} else {
		var classifier = zen('json').getContentObject();
		if (classifier == null) return;
		var rule = classifier.ClassificationMethod.ClassificationRules.Rules[parseInt(ruleIndex)];
		zen('hidPropRuleIndex').setValue(ruleIndex);
		zen('selPropRuleCat').setValue(rule.category);
		zen('txtPropRuleScore').setValue(rule.score);
		zen('chkPropRuleFallback').setProperty('hidden', true);
	}
	zen('modEditRule').show();
}

ClientMethod editRule(category, score = 1, fallback = 0) [ Language = javascript ]
{
	var classifier = zen('json').getContentObject();
	if (classifier == null) return;
	
	var ruleIndex = parseInt(zen('hidPropRuleIndex').getValue());
	if (isNaN(ruleIndex) || (ruleIndex < 0)) {
		var rule = { _class:'%iKnow.Classification.Definition.Rule', category:category, score:score };
		if (fallback==0)
			rule.Predicate = { _class:'%iKnow.Classification.Definition.Predicate', term:1, operator:'greaterThan', value:0 };
		classifier.ClassificationMethod.ClassificationRules.Rules.push(rule);
	} else {
		classifier.ClassificationMethod.ClassificationRules.Rules[ruleIndex].category = category;
		classifier.ClassificationMethod.ClassificationRules.Rules[ruleIndex].score = score;
	}
	zen('json').setContentObject(classifier);
	zenPage.refresh();
	zenPage.endModal();
	zenPage.setProperty('pageModified', true);
}

ClientMethod getPredicateForId(model, predId) [ Language = javascript ]
{
	var idArray = predId.split(':');
	var predicate = model.ClassificationMethod.ClassificationRules.Rules[parseInt(idArray[0])].Predicate;
	var ptr = 1;
	while (ptr < idArray.length) {
		if (predicate._class == '%iKnow.Classification.Definition.PredicateNOT') {
			predicate = predicate.predicate;
		} else {
			predicate = predicate.predicates[parseInt(idArray[ptr])];
		}
		ptr++;
	}
	return predicate;
}

ClientMethod showEditPredicate(predId, show) [ Language = javascript ]
{
	var model = zen('json').getContentObject();
	if (model == null) return;
	
	var predicate = zenPage.getPredicateForId(model, predId);
	
	zen('hidPropPredicateIndex').setValue(predId);
	var type = predicate._class.substr(42);
	zen('selPropPredicateType').setValue(type);
	zenPage.selectPredicateType(predicate, type);
	
	// can we drop this node?
	var idArray = predId.split(':');
	var canBeDropped = (idArray.length > 1);
	if (canBeDropped) {
		idArray.pop();
		var parent = zenPage.getPredicateForId(model, idArray.join(':'));
		canBeDropped = (parent._class.substr(42) != 'NOT');
	}
	zen('btnPropPredicateDrop').setProperty('disabled', !canBeDropped);
	
	if (show) zen('modEditPredicate').show();
}

ClientMethod editPredicate(end) [ Language = javascript ]
{
	var model = zen('json').getContentObject();
	
	var predId = zen('hidPropPredicateIndex').getValue();
	var predicate = zenPage.getPredicateForId(model, predId);
	
	var newType = zen('selPropPredicateType').getValue();
	var oldType = predicate._class.substr(42);
	if (newType != oldType) {
		
		newPredicate = { _class:'%iKnow.Classification.Definition.Predicate'+newType };
		
		if (newType == 'NOT') {
			
			// recycle first predicate from old array, if any
			if ((newType == 'AND') || (newType == 'OR')) {
				if (predicate.predicates.length > 0) {
					newPredicate.predicate = predicate.predicates[0];
				} else {
					newPredicate.predicate = { _class:'%iKnow.Classification.Definition.Predicate', term:1, operator:'greaterThan', value:0 };
				}
			} else {
				newPredicate.predicate =  predicate;
			}
		
		} else if ((newType == 'AND') || (newType == 'OR')) {
			
			// recycle predicates
			if ((oldType=='AND') || (oldType=='OR')) {
				newPredicate.predicates = predicate.predicates;
			} else {
				newPredicate.predicates = new Array();
				newPredicate.predicates[0] = predicate;
			}
			
		} else if (newType == '') {
			
			// set attribute values
			newPredicate.term = zen('selPropPredicateTerm').getValue();
			newPredicate.operator = zen('selPropPredicateOperator').getValue();
			newPredicate.value = zen('txtPropPredicateValue').getValue();
		}
	
		// save predicate into position
		var idArray = predId.split(':');
		if (idArray.length == 1) {
			model.ClassificationMethod.ClassificationRules.Rules[parseInt(idArray[0])].Predicate = newPredicate;
		} else {
			var p = model.ClassificationMethod.ClassificationRules.Rules[parseInt(idArray[0])].Predicate;
			var ptr = 1;
			while (ptr < (idArray.length-1)) {
				if (p._class == '%iKnow.Classification.Definition.PredicateNOT') {
					p = p.predicate;
				} else {
					p = p.predicates[parseInt(idArray[ptr])];
				}
				ptr++;
			}
			if (p._class == '%iKnow.Classification.Definition.PredicateNOT') {
				p.predicate = newPredicate;
			} else {
				p.predicates[parseInt(idArray[ptr])] = newPredicate;
			}
		}
	} else if (newType == '') {
		predicate.term = zen('selPropPredicateTerm').getValue();
		predicate.operator = zen('selPropPredicateOperator').getValue();
		predicate.value = zen('txtPropPredicateValue').getValue();
	}
	
	var sc = zen('json').setContentObject(model);
	zenPage.refresh();
	if (end) zenPage.endModal();
	zenPage.setProperty('pageModified', true);
}

ClientMethod editPredicateAdd() [ Language = javascript ]
{
	// first ensure our predicate is up-to-date
	var sc = zenPage.editPredicate(false);
	
	// add subnode
	var predId = zen('hidPropPredicateIndex').getValue();
	var predicate = zenPage.getPredicateForId(zen('json').getContentObject(), predId);
	var pos = predicate.predicates.length;
	predicate.predicates[pos] = { _class:'%iKnow.Classification.Definition.Predicate', term:1, operator:'greaterThan', value:0 };
	
	// jump to subnode editor
	zenPage.showEditPredicate(predId+':'+pos, false);
}

ClientMethod editPredicateDrop() [ Language = javascript ]
{
	var model = zen('json').getContentObject();
	var idArray = zen('hidPropPredicateIndex').getValue().split(':');
	var p = model.ClassificationMethod.ClassificationRules.Rules[parseInt(idArray[0])].Predicate;
	var ptr = 1;
	while (ptr < (idArray.length-1)) {
		if (p._class == '%iKnow.Classification.Definition.PredicateNOT') {
			p = p.predicate;
		} else {
			p = p.predicates[parseInt(idArray[ptr])];
		}
		ptr++;
	}
	p.predicates.splice(parseInt(idArray[ptr]), 1);
	
	var sc = zen('json').setContentObject(model);
	zenPage.refresh();
	zenPage.endModal();
	zenPage.setProperty('pageModified', true);
}

ClientMethod selectPredicateType(predicate, type) [ Language = javascript ]
{
	if (predicate.length != undefined) { // passed as ID
		predicate = zenPage.getPredicateForId(zen('json').getContentObject(), predicate);
	}
	
	if (type=='') {
		zen('selPropPredicateTerm').setValue(predicate.term);
		zen('selPropPredicateTerm').setProperty('hidden', false);
		zen('selPropPredicateOperator').setValue(predicate.operator);
		zen('selPropPredicateOperator').setProperty('hidden', false);
		zen('txtPropPredicateValue').setValue(predicate.value);
		zen('txtPropPredicateValue').setProperty('hidden', false);
		zen('btnPropPredicateAdd').setProperty('hidden', true);
	} else {
		zen('selPropPredicateTerm').setValue(1);
		zen('selPropPredicateTerm').setProperty('hidden', true);
		zen('selPropPredicateOperator').setValue('greaterThan');
		zen('selPropPredicateOperator').setProperty('hidden', true);
		zen('txtPropPredicateValue').setValue(0);
		zen('txtPropPredicateValue').setProperty('hidden', true);
		zen('btnPropPredicateAdd').setProperty('hidden', (type=='NOT'));
	}
}

Method PopulateTerms(pMetric As %String, pCount As %Integer) As %Status [ ZenMethod ]
{
	set tSC = $$$OK
	try {
		#dim tBuilder As %iKnow.Classification.Builder
		set tSC = ##class(%iKnow.Classification.Builder).%LoadFromDefinition(..definitionClass, .tBuilder, 0)
		quit:$$$ISERR(tSC)
		
		// we might not have categories yet if this is called from createClassifier() !
		set tSC = tBuilder.%GetCategoryInfo(.tCats)
		quit:$$$ISERR(tSC)
		if '$g(tCats) {
			set tSC = tBuilder.%LoadMetadataCategories(tBuilder.MetadataField)
			quit:$$$ISERR(tSC)
		}
		
		set tSC = tBuilder.%PopulateTerms(pCount,, pMetric, 1)
		quit:$$$ISERR(tSC)
		
		set tSC = tBuilder.%CreateClassifierClass(..definitionClass, 0, 1, 1, 0)
		quit:$$$ISERR(tSC)
		
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	if $$$ISERR(tSC) {
		set tMessage = $zconvert($system.Status.GetErrorText(tSC),"O","JS")
		&js<alert('#(tMessage)#');>
	}
	quit tSC
}

Method GenerateRuleSet() As %Status [ ZenMethod ]
{
	set tSC = $$$OK
	try {
		
		set tSC = ##class(%iKnow.Classification.Builder).%LoadFromDefinition(..definitionClass, .tBuilder)
		quit:$$$ISERR(tSC)
		
		// will be forwarded to rules implementation class
		set tSC = tBuilder.%GenerateRules()
		quit:$$$ISERR(tSC)
		
		set tSC = tBuilder.%CreateClassifierClass(..definitionClass, 0, 1, 1, 0)
		quit:$$$ISERR(tSC)
		
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	if $$$ISERR(tSC) {
		set tMessage = $zconvert($system.Status.GetErrorText(tSC),"O","JS")
		&js<alert('#(tMessage)#');>
	}
	quit tSC
}

///  Defines SVG-specific CSS style sheet used by an object/component.
XData SVGStyle
{
<style type="text/css">

.tcRuleRect {
	stroke: #333333;
	fill: white;
	cursor: pointer;
}
.tcRuleText {
	font-size: 14px;
	cursor: pointer;
}

.tcRuleFallback .tcRuleRect {
	stroke-dasharray: 6,4;
}
.tcRuleFallback .tcRuleText {
	fill: #333333;
}

.tcRuleOR .tcRuleRect,
.tcRuleAND .tcRuleRect {
	stroke: Navy;
}
.tcRuleNOT .tcRuleRect {
	stroke: DarkRed;
}

.tcRuleOR .tcRuleText,
.tcRuleAND .tcRuleText {
	fill: Navy;
}
.tcRuleNOT .tcRuleText {
	fill: DarkRed;
}

.tcConnectorOR, .tcConnectorAND {
	fill: none;
	stroke: Navy;
}
.tcConnectorNOT {
	fill: none;
	stroke: DarkRed;
}

</style>
}

Method OnDrawRibbon() As %Status
{
	&html<<td><img src="images/spacer.gif" height="1" width="20"></td>>
	
	set tImage = $s(..hideAdvanced:"ds2_gear2_44.png", 1:"ds2_gear_44.png")
	set tTitle = $s(..hideAdvanced:"Show advanced options", 1:"Hide advanced options")
	set tStyle = $s(..hideAdvanced:"opacity:0.3;", 1:"")
	&html<<td><img src="deepsee/ds2_gear2_44.png" class="btnAdvancedMode" style="#(tStyle)#" onclick="zenPage.toggleAdvancedMode(!zenPage.getProperty('hideAdvanced'));" title="#(tTitle)#" /></td>>
	
	&html<<td width="40%">&nbsp;</td>>
	
	quit $$$OK
}

ClientMethod toggleAdvancedMode(hide) [ Language = javascript ]
{
	var sc = zenPage.setProperty('hideAdvanced', hide);
	
	zen('grpTermProps').setProperty('hidden', hide);
	zen('btnTermEdit').setProperty('hidden', hide);
	zen('selLocalTermWeights').setProperty('hidden', hide);
	zen('selTermNormalization').setProperty('hidden', hide);
	
	var displayList = 'Naive Bayes,Decision rules';
	var valueList = 'naiveBayes,rules';
	if (!hide) {
		displayList += ',Cosine similarity,Euclidean distance,PMML';
		valueList += ',cosineSimilarity,euclideanDistance,pmml';
	}
	zen('selMethod').setProperty('valueList', valueList);
	zen('selMethod').setProperty('displayList', displayList);
	
	zen('toolRibbon').refreshContents();
}

Method DrawSelectAllNone(pSeed As %String) As %Status
{
	&html<<span style="font-size:11px;">select <a style="color:#777777;" href="javascript:zenPage.selectAllTerms('#(pSeed)#')">all</a> / <a style="color:#777777;" href="javascript:zenPage.selectNoTerms('#(pSeed)#')">none</a></span>>
	quit $$$OK
}

ClientMethod selectNoTerms(type) [ Language = javascript ]
{
	zen('hid'+type).setValue('');
	var checkboxes = document.getElementsByName('chk'+type);
	for (var i = 0; i<checkboxes.length; i++) {
		checkboxes[i].checked = false;
	}
}

ClientMethod selectAllTerms(type) [ Language = javascript ]
{
	var checkboxes = document.getElementsByName('chk'+type);
	for (var i = 0; i<checkboxes.length; i++) {
		checkboxes[i].checked = true;
		sc = zenPage.toggleElement(type, checkboxes[i].title);
	}
}

Method DrawOptimizerTerms(pSeed As %String) As %Status
{
	set tSC = $$$OK
	try {
		&html<<ul>>
		
		merge tTerms = ^IRIS.Temp.IK.Optimizer(..optimizerTask,"terms")
		set i = ""
		for {
			set i = $order(tTerms(i), 1, tTermValue)
			quit:i=""
			
			// TODO: refine
			&html<<li>#(tTermValue)#</li>>
		}
		
		&html<<ul>>
		
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit tSC
}

Method OptimizeLoadTerms(pMode As %String, pSpec As %String) As %Status [ ZenMethod ]
{
	set tSC = $$$OK
	try {
		set tOptimizer = ##class(%iKnow.Classification.Optimizer).%New(..optimizerTask, 0)
		
		if (pMode="SQL") {
			
			set tSC = tOptimizer.LoadTermsSQL(pSpec)
			quit:$$$ISERR(tSC)
			
		} else {
			set tCount = $s(+pSpec:+pSpec, 1:100)
			
			// ignore training set for performance here
			if (pMode="BM25") {
				set tSC = ##class(%iKnow.Queries.EntityAPI).GetTopBM25(.tResult, ..domain, 1, tCount)
			} elseif (pMode="TFIDF") {
				set tSC = ##class(%iKnow.Queries.EntityAPI).GetTopTFIDF(.tResult, ..domain, 1, tCount)
			} elseif (pMode="Dominance") {
				set tSC = ##class(%iKnow.Semantics.DominanceAPI).GetProfileByDomain(.tResult, ..domain, 1, tCount, $$$SDCONCEPT)
				
				// unpack $lb's:
				s i="" f { s i = $o(tResult(i),1,tData) q:i=""  s tResult(i)=$lb(,$lg($lg(tData,2),1)) }
			} else {
				set tSC = $$$ERROR($$$GeneralError, "Unknown term selection mode: '"_pMode_"'")
				quit
			}
			quit:$$$ISERR(tSC)
		
			set tSC = tOptimizer.LoadTermsArray(.tResult, 2)
			quit:$$$ISERR(tSC)
		}
		
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	
	if $$$ISERR(tSC) {
		set tMessage = $zconvert($system.Status.GetErrorText(tSC), "O", "JS")
		&js<alert('#(tMessage)#');>
	}
	
	&js<zen('htmlOptimizerTerms').refreshContents();>
	
	quit tSC
}

}
