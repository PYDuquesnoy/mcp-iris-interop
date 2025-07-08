/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include %IFInclude

/// <p><b>Please note this version of the REST API is deprecated. See <class>%iKnow.REST.v1dot1</class> for a newer version.</b></p>
/// <p>This class offers endpoints for accessing iKnow functionalities over REST.</p>
/// <p>The API is fully documented using the <a href="https://github.com/OAI/OpenAPI-Specification">OpenAPI Specification</a>
/// (also known as <a href="http://www.swagger.io">Swagger</a>). The description in YAML is
/// available from the "/swagger" endpoint and can be loaded directly into <a href="https://github.com/swagger-api/swagger-ui/blob/master/README.md">swagger-ui</a> for
/// convenient GUI capabilities on top of this API.</p>
/// 
/// <example language="swagger">
/// swagger: '2.0'
/// 
/// info:
///   version: "1.0.0"
///   title: iKnow REST APIs
///   description: |
///     This is the [OpenAPI Specification](https://github.com/OAI/OpenAPI-Specification) 
///     of the iKnow REST APIs, giving you RESTful access to iKnow domain contents in your system
///     Use [swagger-ui](https://github.com/swagger-api/swagger-ui/blob/master/README.md)
///     or a similar tool to conveniently browse and test these APIs.
///     For more information on iKnow, visit [intersystems.com](http://www.intersystems.com)
/// 
///   contact:
///     name: InterSystems
///     url: http://wrc.intersystems.com
///     email: support@intersystems.com
/// 
///   license:
///     name: Copyright InterSystems Corporation, all rights reserved.
///     url: https://www.intersystems.com/noticesterms-conditions/
/// 
/// consumes:
///   - application/json
/// produces:
///   - application/json
/// 
/// 
/// parameters:
///   domainParam:
///     name: domain
///     type: integer
///     in: path
///     description: the ID of the domain to query
///     required: true
///   sourceParam:
///     name: source
///     type: integer
///     in: path
///     description: the source ID to query for
///     required: true
///   tableParam:
///     name: table
///     type: string
///     in: path
///     description: the table containing iFind index
///     required: true
/// 
/// 
/// definitions:
///   PageNumber:
///     type: integer
///     description: |
///       which "page" of the results to retrieve
///     default: 1
/// 
///   PageSize:
///     type: integer
///     description: |
///       how many results to retrieve per "page"
///     default: {{{PAGESIZE}}}
/// 
///   FilterMode:
///     description: filter mode to use for optionally recalculating certain metrics. Defaults to recalculating all and re-sorting the results (15).
///     type: integer
///     default: 15
///     example: 15
///     enum: [1, 3, 5, 7, 11, 13, 15]
/// 
///   IncludeCount:
///     description: whether or not to include a count of all results (ignoring page and pageSize)
///     type: boolean
///     default: 0
///     format: integer
/// 
///   CountOnly:
///     description: whether or not to retrieve just the count and no result list
///     type: boolean
///     default: 0
///     format: integer
/// 
///   Blacklists:
///     description: array of blacklist IDs or names to use for limiting query results, OR a valid SELECT clause retrieving entity values outright
///     type: array
///     default: []
///     items:
///       type: string
///     
///   Filter:
///     # TODO: move into proper hierarchy once swagger-ui supports it
///     description: filter object restricting the sources to be considered in this query
///     type: object
///     example: 
///       { "operator": "OR", 
///         "filters": [ { "ids": [ 123 ] }, 
///                      {"field": "Year", "operator": ">", "value": 2016 } ] }
///     properties:
///       ids:
///         description: for use with source-ID-based filters
///         type: array
///         items:
///           type: integer
///       extIds:
///         description: for use with external-ID-based filters
///         type: array
///         items:
///           type: string
///       operator:
///         description: for use with group filters ("AND"|"OR") or metadata-based filters (any other value)
///         type: string
///         enum: ["AND", "OR", "=", "!=", "<", ">", ">=", "<=", "BETWEEN", "IS NULL", "IS NOT NULL"]
///       field:
///         description: for use with metadata-based filters
///         type: string
///       value:
///         description: for use with metadata-based filters
///         type: string
///       negate:
///         description: for use with group filters
///         type: boolean
///         default: false
///       filters:
///         description: for use with group filters
///         type: array
///         items:
///           $ref: '#/definitions/Filter'
///       className:
///         description: use for filters not covered by other shorthands
///         type: string
///         example: '%iKnow.Filters.ContainsEntityFilter'
///       arguments:
///         description: for use with 'className' property, any arguments to be passed to the filter's %New() method (except domain ID)
///         type: array
///         items:
///           type: string
///   
///   HighlightingRule:
///     description: |
///       "style" property is mandatory, then pick one selector per rule
///     type: object
///     required: ["style"]
///     properties:
///       style:
///         type: string
///         description: |
///           style specification for this highlighting rule: either a two-character 
///           sequence or a HTML tag to use for wrapping the to-be-highlighted element.
///           Use one selector per highlighting rule.
///       entities:
///         type: array
///         items:
///           type: string
///         description: <i>selector</i> - selects list of entities
///       role:
///         type: string
///         enum: ["concept", "relation", "pathRelevant", "nonRelevant" ]
///         description: <i>selector</i> - selects all entities with this role
///       attribute:
///         type: string
///         enum: ["negation", "positiveSentiment", "negativeSentiment" ]
///         description: <i>selector</i> - selects all entities affected by this attribute
///       attributeWords:
///         type: string
///         enum: ["negation", "positiveSentiment", "negativeSentiment" ]
///         description: <i>selector</i> - selects all marker terms indicating this attribute
///       anyMatch:
///         type: boolean
///         description: <i>selector</i> - selects any dictionary match
///       dictionaries:
///         type: array
///         description: <i>selector</i> - selects any dictionary match of the specified dictionary IDs
///         items:
///           type: integer
///       dictionaryItems:
///         type: array
///         description: <i>selector</i> - selects any dictionary match of the specified dictionary item IDs
///         items:
///           type: integer
///       matchType:
///         type: string
///         enum: ["full", "partial"]
///         description: |
///           refines the "anyMatch", "dictionaries" or "dictionaryItems" selectors to the designated match type
/// 
///   Highlighting:
///     description: array of highlighting rules
///     example:
///       [ { "style": "[]", "role": "concept" },
///         { "style": "<b>", "entities": [ "airplane", "pilot" ] } ]
///     type: array
///     items:
///       $ref: '#/definitions/HighlightingRule'
/// 
///   DomainList:
///     type: object
///     required: ["domains"]
///     properties:
///       domains:
///         type: array
///         items:
///           title: Domain
///           type: object
///           required: ["id", "name" ]
///           properties:
///             id:
///               type: integer
///             name:
///               type: string
///             definitionClass:
///               type: string
///             sourceCount:
///               type: integer
///             version:
///               type: integer
///   
///   DomainDetails:
///     type: object
///     required: ["id", "name"]
///     properties:
///       id:
///         type: integer
///       name: 
///         type: string
///       parameters:
///         type: object
///       metadata:
///         type: array
///         items:
///           type: object
///           required: ["id", "name", "operators", "dataType", "storage"]
///           properties:
///             id:
///               type: integer
///             name:
///               type: string
///             operators:
///               type: array
///               items:
///                 $ref: '#/definitions/MetadataOperator'
///             dataType:
///               type: string
///               enum: ["string", "number", "date"]
///             storage:
///               type: string
///               
/// 
///   MetadataOperator:
///     type: string
///     enum: [ "=", "!=", "<", ">", ">=", "<=", "BETWEEN", "IS NULL", "IS NOT NULL" ]
///   
///   ConfigurationList:
///     type: object
///     required: ["configurations"]
///     properties:
///       configurations:
///         type: array
///         items:
///           title: Configuration
///           type: object
///           required: ["id", "name", "languages"]
///           properties:
///             id:
///               type: integer
///             name:
///               type: string
///             languages:
///               type: array
///               items:
///                 $ref: '#/definitions/LanguageCode'
///             userDictionary:
///                 $ref: '#/definitions/UserDictionary'
///             maxConceptLength:
///               type: integer
///   
///   UserDictionary:
///     type: object
///     required: ["entries"]
///     properties:
///       name:
///         type: string
///       entries:
///         type: array
///         items:
///           title: UserDictionaryEntry
///           type: object
///           required: ["string"]
///           properties:
///             string:
///               type: string
///             rewrite:
///               type: string
///             label:
///               type: string
/// 
///   LanguageCode:
///     description: 2-letter ISO language code
///     type: string
///     enum: [ "en", "fr", "de", "es", "pt", "nl", "ru", "uk", "se", "ja" ]
/// 
///   SourceList:
///     description: list of sources
///     type: object
///     required: ["sources"]
///     properties:
///       sources:
///         type: array
///         items:
///           title: Source
///           type: object
///           required:
///             - id
///             - extId
///           properties:
///             id:
///               type: integer
///               description: source ID
///             extId:
///               type: string
///               description: external ID
///             metadata:
///               type: object
///               description: map of metadata field values
///             snippet:
///               type: string
///               description: snippet (summary) of the retrieved source
///       count:
///         description: number of result sources (ignoring page and pageSize)
///         type: integer
///   
/// 
///   EntityList:
///     description: list of entities
///     type: object
///     properties:
///       entities:
///         type: array
///         items:
///           $ref: '#/definitions/Entity'
///       count:
///         type: integer
///         description: number of result entities (ignoring page and pageSize)
/// 
///   Entity:
///     type: object
///     required:
///       - id
///       - value
///     properties:
///       id:
///         type: integer
///         description: unique entity ID
///       value:
///         type: string
///         description: entity value
///       frequency:
///         type: integer
///         description: number of times the entity occurs in the result set
///       spread:
///         type: integer
///         description: number of distinct sources the entity occurs in in the result set
///     
/// 
///   CRCList:
///     type: object
///     required:
///       - crcs
///     properties:
///       crcs:
///         type: array 
///         items:
///           title: CRC
///           type: object
///           required:
///             - id
///             - relation
///             - frequency
///             - spread
///           properties:
///             id:
///               type: integer
///               description: unique entity ID
///             master: 
///               type: string
///               description: entity value of the master concept
///             relation: 
///               type: string
///               description: entity value of the relation
///             slave: 
///               type: string   
///               description: entity value of the slave concept
///             frequency:
///               type: integer
///               description: number of times the CRC occurs in the result set
///             spread:
///               type: integer
///               description: number of distinct sources the CRC occurs in in the result set
///       count:
///         type: integer
///         description: number of result CRCs (ignoring page and pageSize)
/// 
///   CRC:
///     type: object
///     required:
///       - relation
///     properties:
///       master: 
///         type: string
///         description: entity value of the master concept
///       relation: 
///         type: string
///         description: entity value of the relation
///       slave: 
///         type: string   
///         description: entity value of the slave concept
/// 
///   BlacklistList:
///     type: object
///     required: ["blacklists"]
///     properties:
///       blacklists:
///         type: array
///         items:
///           $ref: '#/definitions/BlacklistDetails'
/// 
///   BlacklistDetails:
///     type: object
///     required: ["id", "name"]
///     properties:
///       id:
///         type: integer
///       name:
///         type: string
///       description:
///         type: string
///       elements:
///         type: array
///         items:
///           type: string
///  
///   DictionaryList:
///     type: object
///     required: ["dictionaries"]
///     properties:
///       dictionaries:
///         type: array
///         items:
///           $ref: '#/definitions/DictionaryDetails'
///       count:
///         type: integer
///         description: total number of dictionaries (ignoring page and pageSize)
/// 
///   DictionaryDetails:
///     type: object
///     required: ["id", "name"]
///     properties:
///       id:
///         type: integer
///       name:
///         type: string
///       language:
///         $ref: '#/definitions/LanguageCode'
///       description:
///         type: string
///       items:
///         type: array
///         items:
///           $ref: '#/definitions/DictionaryItemDetails'
/// 
///   DictionaryItemDetails:
///     type: object
///     required: ["id", "name", "uri"]
///     properties:
///       id:
///         type: integer
///       name:
///         description: display label
///         type: string
///       uri:
///         description: unique, domain-wide identifier for this Dictionary Item
///         type: string
///       language:
///         $ref: '#/definitions/LanguageCode'
///       terms:
///         type: array
///         items:
///           $ref: '#/definitions/DictionaryTermDetails'
/// 
///   DictionaryTermDetails:
///     type: object
///     required: ["id"]
///     example: { id: 123, string: "palm tree" }
///     properties:
///       id:
///         type: integer
///       language:
///         $ref: '#/definitions/LanguageCode'
///       string:
///         description: if this is a regular term, the term string value
///         type: string
///       regexp:
///         description: if this is a regular expression format term, the regular expression
///         type: string
///       replace:
///         description: if this is a regular expression format term, the replacement string
///         type: string
///       formatClass:
///         description: if this is a format term, the name of the format implementation class
///         type: string
///       formatParams:
///         description: if this is a format term, any additional parameters for the format implementation class
///         type: array
///         items:
///           type: string
/// 
///   MatchList:
///     type: object
///     required: ["matches"]
///     properties:
///       matches:
///         type: array
///         items:
///           $ref: '#/definitions/MatchListItem'
/// 
///   MatchListItem:
///     type: object
///     required: [ "id", "score" ]
///     properties:
///       id:
///         type: integer
///       score:
///         type: number
///         description: aggregated score for this match
///       partialCount:
///         type: integer
///         description: number of partially matched entities for this match
///       ordered:
///         type: boolean
///         format: integer
///         description: whether or not the matched entities appear in the term's order
///       negatedCount:
///         type: integer
///         description: number of entities
///       term:
///         type: object
///         title: MatchedTerm
///         required: ["id","item"]
///         properties:
///           id:
///             type: integer
///           string:
///             type: string
///           item:
///             title: MatchedItem
///             type: object
///             required: ["id", "uri", "name", "dictionary" ]
///             properties:
///               id:
///                 type: integer
///               name:
///                 type: string
///               uri:
///                 type: string
///               dictionary:
///                 title: MatchedDictionary
///                 type: object
///                 required: ["id", "name"]
///                 properties:
///                   id:
///                     type: integer
///                   name:
///                     type: string
///       target:
///         title: MatchTarget
///         type: object
///         description: the matched piece of the source text
///         properties:
///           id:
///             type: integer
///           type:
///             type: string
///             enum: ["entity", "crc", "path", "sentence"]
///       sentenceId:
///         type: integer
///       sentence:
///         type: string
///         description: full text of the sentence where the match occurred
///       elements:
///         type: array
///         description: detailed overview of entity-level match results
///         items:
///           type: object
///           title: MatchedElements
///           required: ["partId", "literal", "score", "role", "matchedWords", "negated"]
///           properties:
///             partId:
///               type: integer
///               description: entity occurrence / part ID of the matched sentence part
///             literal:
///               type: string
///               description: literal string how this part appeared in the sentence
///             score:
///               type: number
///               description: entity-level score
///             role:
///               type: string
///               enum: ["concept", "relation", "pathRelevant" ]
///               description: role of this sentence part
///             matchedWords:
///               type: string
///               description: which words within the entity actually matched
///             negated:
///               type: boolean
///               format: integer
///               description: whether this sentence part is part of a negative context
///             entityId:
///               type: integer
///               description: entity ID, if this part corresponds to an entity
///             entity:
///               type: string
///               description: entity value, if this part corresponds to an entity
///             output:
///               type: string
///               description: format output, if this part corresponds to a matched format providing output
///                   
/// 
///   SentenceDetails:
///     type: object
///     required:
///       - id
///       - sourceId
///       - text
///     properties:
///       id:
///         description: sentence ID
///         type: integer
///       sourceId:
///         description: containing source ID
///         type: integer
///       text:
///         description: sentence text, optionally highlighted
///         type: string
///       parts:
///         description: entities in this sentence
///         type: array
///         items:
///           title: SentencePart
///           type: object
///           required:
///             - partId
///             - literal
///             - role
///           properties:
///             partId:
///               description: entity / part occurrence ID
///               type: integer
///             literal:
///               description: literal value of this part in the sentence
///               type: string
///             role:
///               description: role of this entity in the path
///               type: string
///               enum: ["concept", "relation", "pathRelevant"]
///             entityId:
///               description: unique entity ID, if this is not a non-relevant
///               type: integer
///             entity:
///               description: entity value, if this is not a non-relevant
///               type: string
///             stemId:
///               description: stem ID for this entity, if the domain is configured for stemming
///               type: string
///             stem:
///               description: stem value of this entity, if the domain is configured for stemming
///               type: string
///             attributes:
///               description: semantic attributes for this entity
///               type: array
///               items:
///                 title: AttributeInfo
///                 type: object
///                 required: ["type", "level"]
///                 properties:
///                   type:
///                     description: name of the attribute
///                     type: string
///                   level:
///                     description: level at which the attribute applies
///                     type: string
///                     enum: ["path", "word"] 
///                   words:
///                     description: if level="word", the actual words affected
///                     type: string
///                   properties:
///                     description: attribute properties
///                     type: object
/// 
///   HighlightSpec:
///     # TODO: move into proper hierarchy once swagger-ui supports it
///     description: The parameters needed for %iFind.Utils.Highlight
///     type: object
///     example: 
///       { "tag": "<b>", "limit":0, "name": "Highlighted"}
///     properties:
///       tag:
///         description: the tags used to enclose the highlighted segments
///         type: string
///         default: "<b>"
///       limit:
///         description: limit the segments get highlighted,check %iFind.Utils.Highlight() for details
///         type: integer
///         default: 0 
///       name:
///         description: the alias name for the column containing highlighted text
///         type: string
///         default: "Highlighted"
///   RankSpec:
///     # TODO: move into proper hierarchy once swagger-ui supports it
///     description: The parameters needed for %iFind.Utils.Rank
///     type: object
///     example: 
///       { "name":"Rank" }
///     properties:
///       name:
///         description: the alias name for the column containing rank info
///         type: string
///         default: "Rank"
///   OptionSpec:
///     description: The option could be object which includes all the required parameters. However, you could still use "0","1","2","3","4" these simple strings for option for the legacy support
///     type: object
///     properties:
///       mode:
///         type: string
///         enum: ["0","1","2","3","4","*","normal","stemmed","decompounded","fuzzy","regex"]
///         description: the iFind search options. 0/normal search,1/stemmed search,2/decompunded search,3/fuzzy search,4/regex search, "*" indicates use the index setting
///       stemmer:
///         type: string
///         description: the stemming/decompounding class
///       arguments:
///         type: array
///         description: the arguments needed for initialize a stemming/decompounding class
///         items:
///           type: string
///       distance:
///         type: string
///         description: the fuzzy search threshold.
/// </example>
Class %iKnow.REST.v1 Extends (Base, Utils) [ Deprecated, System = 4 ]
{

Parameter SNIPPETSIZE = 2;

XData UrlMap [ XMLNamespace = "http://www.intersystems.com/urlmap" ]
{
<Routes>

<!-- Entities -->
<Route Url="/domain/:domain/entities" Method="GET" Call="GetEntitiesGET" />
<Route Url="/domain/:domain/entities" Method="POST" Call="GetEntities" />
<Route Url="/domain/:domain/entities/:string/similar" Method="GET" Call="GetSimilarEntitiesGET" />
<Route Url="/domain/:domain/entities/:string/similar" Method="POST" Call="GetSimilarEntities" />
<Route Url="/domain/:domain/entities/similar" Method="POST" Call="GetSimilarEntitiesPOST" />
<Route Url="/domain/:domain/entities/:entity/related" Method="GET" Call="GetRelatedEntitiesGET" />
<Route Url="/domain/:domain/entities/:entity/related" Method="POST" Call="GetRelatedEntities" />
<Route Url="/domain/:domain/entities/related" Method="POST" Call="GetRelatedEntitiesPOST" />
<Route Url="/domain/:domain/entities/:entity/details" Method="GET" Call="GetEntityDetailsGET" />
<Route Url="/domain/:domain/entities/:entity/details" Method="POST" Call="GetEntityDetails" />
<Route Url="/domain/:domain/entities/details" Method="POST" Call="GetEntityDetailsPOST" />


<!-- Sources -->
<Route Url="/domain/:domain/sources" Method="GET" Call="GetSourcesGET" />
<Route Url="/domain/:domain/sources" Method="POST" Call="GetSources" />
<Route Url="/domain/:domain/sources/by/entity/:entity" Method="GET" Call="GetSourcesByEntityGET" />
<Route Url="/domain/:domain/sources/by/entity/:entity" Method="POST" Call="GetSourcesByEntity" />
<Route Url="/domain/:domain/sources/by/entity" Method="POST" Call="GetSourcesByEntityPOST" />
<Route Url="/domain/:domain/sources/by/crc/:crc" Method="GET" Call="GetSourcesByCRCGET" />
<Route Url="/domain/:domain/sources/by/crc/:crc" Method="POST" Call="GetSourcesByCRC" />
<Route Url="/domain/:domain/sources/by/crc" Method="POST" Call="GetSourcesByCRCPOST" />
<Route Url="/domain/:domain/sources/:source/similar" Method="GET" Call="GetSimilarSourcesGET" />
<Route Url="/domain/:domain/sources/:source/similar" Method="POST" Call="GetSimilarSources" />
<Route Url="/domain/:domain/sources/:source/details" Method="GET" Call="GetSourceDetailsGET" />
<Route Url="/domain/:domain/sources/:source/details" Method="POST" Call="GetSourceDetails" />

<Route Url="/domain/:domain/sources/new" Method="POST" Call="AddSource" />
<Route Url="/domain/:domain/sources/:source/drop" Method="GET" Call="DropSourceGET" />
<Route Url="/domain/:domain/sources/:source/drop" Method="POST" Call="DropSource" />
<Route Url="/domain/:domain/sources/:source" Method="DELETE" Call="DropSourceGET" />
<Route Url="/domain/:domain/sources/:source/set/metadata" Method="POST" Call="SetMetadata" />


<!-- Sentences -->
<Route Url="/domain/:domain/sentences/by/entity/:entity" Method="GET" Call="GetSentencesByEntityGET" />
<Route Url="/domain/:domain/sentences/by/entity/:entity" Method="POST" Call="GetSentencesByEntity" />
<Route Url="/domain/:domain/sentences/by/entity" Method="POST" Call="GetSentencesByEntityPOST" />
<Route Url="/domain/:domain/sentences/:id/details" Method="GET" Call="GetSentenceDetailsGET" />
<Route Url="/domain/:domain/sentences/:id/details" Method="POST" Call="GetSentenceDetails" />


<!-- Paths and CRCs -->
<Route Url="/domain/:domain/crcs" Method="GET" Call="GetCRCsGET" />
<Route Url="/domain/:domain/crcs" Method="POST" Call="GetCRCs" />
<Route Url="/domain/:domain/crcs/by/entity/:entity" Method="GET" Call="GetCRCsByEntityGET" />
<Route Url="/domain/:domain/crcs/by/entity/:entity" Method="POST" Call="GetCRCsByEntity" />
<Route Url="/domain/:domain/crcs/by/entity" Method="POST" Call="GetCRCsByEntityPOST" />

<Route Url="/domain/:domain/paths/by/entity/:entity" Method="GET" Call="GetPathsByEntityGET" />
<Route Url="/domain/:domain/paths/by/entity/:entity" Method="POST" Call="GetPathsByEntity" />
<Route Url="/domain/:domain/paths/by/entity" Method="POST" Call="GetPathsByEntityPOST" />


<!-- Blacklists -->
<Route Url="/domain/:domain/blacklists" Method="GET" Call="GetBlacklistsGET" />
<Route Url="/domain/:domain/blacklists" Method="POST" Call="GetBlacklists" />
<Route Url="/domain/:domain/blacklists/new/:name" Method="GET" Call="CreateBlacklistGET" />
<Route Url="/domain/:domain/blacklists/new/:name" Method="POST" Call="CreateBlacklist" />
<Route Url="/domain/:domain/blacklists/new" Method="POST" Call="CreateBlacklistPOST" />
<Route Url="/domain/:domain/blacklists/:id/details" Method="GET" Call="GetBlacklistDetails" />
<Route Url="/domain/:domain/blacklists/:id/details" Method="POST" Call="GetBlacklistDetails" />
<Route Url="/domain/:domain/blacklists/:id/drop" Method="GET" Call="DropBlacklist" />
<Route Url="/domain/:domain/blacklists/:id/drop" Method="POST" Call="DropBlacklist" />
<Route Url="/domain/:domain/blacklists/:id" Method="DELETE" Call="DropBlacklist" />
<Route Url="/domain/:domain/blacklists/:id/clear" Method="GET" Call="ClearBlacklist" />
<Route Url="/domain/:domain/blacklists/:id/clear" Method="POST" Call="ClearBlacklist" />
<Route Url="/domain/:domain/blacklists/:id/add/:string" Method="GET" Call="AddStringToBlacklistGET" />
<Route Url="/domain/:domain/blacklists/:id/add/:string" Method="POST" Call="AddStringToBlacklist" />
<Route Url="/domain/:domain/blacklists/:id/add" Method="POST" Call="AddStringToBlacklistPOST" />
<Route Url="/domain/:domain/blacklists/:id/remove/:string" Method="GET" Call="RemoveStringFromBlacklistGET" />
<Route Url="/domain/:domain/blacklists/:id/remove/:string" Method="POST" Call="RemoveStringFromBlacklist" />
<Route Url="/domain/:domain/blacklists/:id/remove" Method="POST" Call="RemoveStringFromBlacklistPOST" />


<!-- Dictionaries & Matching -->
<Route Url="/domain/:domain/matching/dictionaries" Method="GET" Call="GetDictionariesGET" />
<Route Url="/domain/:domain/matching/dictionaries" Method="POST" Call="GetDictionaries" />
<Route Url="/domain/:domain/matching/dictionaries/new/:name" Method="GET" Call="CreateDictionaryGET" />
<Route Url="/domain/:domain/matching/dictionaries/new/:name" Method="POST" Call="CreateDictionary" />
<Route Url="/domain/:domain/matching/dictionaries/new" Method="POST" Call="CreateDictionaryPOST" />
<Route Url="/domain/:domain/matching/dictionaries/:id/details" Method="GET" Call="GetDictionaryDetails" />
<Route Url="/domain/:domain/matching/dictionaries/:id/details" Method="POST" Call="GetDictionaryDetails" />
<Route Url="/domain/:domain/matching/dictionaries/:id/drop" Method="GET" Call="DropDictionary" />
<Route Url="/domain/:domain/matching/dictionaries/:id/drop" Method="POST" Call="DropDictionary" />
<Route Url="/domain/:domain/matching/dictionaries/:id" Method="DELETE" Call="DropDictionary" />
<Route Url="/domain/:domain/matching/dictionaries/:id/add/items" Method="POST" Call="CreateDictionaryItems" />

<Route Url="/domain/:domain/matching/items/new" Method="POST" Call="CreateDictionaryItemsPOST" />
<Route Url="/domain/:domain/matching/items/:id/details" Method="GET" Call="GetDictionaryItemDetails" />
<Route Url="/domain/:domain/matching/items/:id/details" Method="POST" Call="GetDictionaryItemDetails" />
<Route Url="/domain/:domain/matching/items/:id/drop" Method="GET" Call="DropDictionaryItem" />
<Route Url="/domain/:domain/matching/items/:id/drop" Method="POST" Call="DropDictionaryItem" />
<Route Url="/domain/:domain/matching/items/:id" Method="DELETE" Call="DropDictionaryItem" />
<Route Url="/domain/:domain/matching/items/:id/add/terms" Method="POST" Call="CreateDictionaryTerms" />

<Route Url="/domain/:domain/matching/terms/new" Method="POST" Call="CreateDictionaryTermsPOST" />
<Route Url="/domain/:domain/matching/terms/:id/drop" Method="GET" Call="DropDictionaryTerm" />
<Route Url="/domain/:domain/matching/terms/:id/drop" Method="POST" Call="DropDictionaryTerm" />
<Route Url="/domain/:domain/matching/terms/:id" Method="DELETE" Call="DropDictionaryTerm" />

<Route Url="/domain/:domain/matching/match" Method="GET" Call="MatchAllGET" />
<Route Url="/domain/:domain/matching/match" Method="POST" Call="MatchAll" />
<Route Url="/domain/:domain/matching/match/:source" Method="GET" Call="MatchSourceGET" />
<Route Url="/domain/:domain/matching/match/:source" Method="POST" Call="MatchSource" />

<Route Url="/domain/:domain/matching/matches/by/source/:id" Method="GET" Call="GetMatchesBySourceGET" />
<Route Url="/domain/:domain/matching/matches/by/source/:id" Method="POST" Call="GetMatchesBySource" />
<Route Url="/domain/:domain/matching/matches/by/item/:id" Method="GET" Call="GetMatchesByItemGET" />
<Route Url="/domain/:domain/matching/matches/by/item/:id" Method="POST" Call="GetMatchesByItem" />


<!-- Miscellaneous -->
<Route Url="/index" Method="POST" Call="IndexSYS" />
<Route Url="/domain/:domain/index" Method="POST" Call="Index" />
<Route Url="/highlight" Method="POST" Call="HighlightSYS" />
<Route Url="/domain/:domain/highlight" Method="POST" Call="Highlight" />

<Route Url="/domains" Method="GET" Call="GetDomains" />
<Route Url="/domains" Method="POST" Call="GetDomains" />
<Route Url="/configurations" Method="GET" Call="GetConfigurationsGET" />
<Route Url="/configurations" Method="POST" Call="GetConfigurations" />

<Route Url="/domain/:domain/details" Method="GET" Call="GetDomainDetails" />
<Route Url="/domain/:domain/details" Method="POST" Call="GetDomainDetails" />

<Route Url="/swagger" Method="GET" Call="GetSwagger" />

<!--iFind-->
<Route Url="/table/:table/search" Method="POST" Call="SearchIndex" />


</Routes>
}

/// <example language="swagger">
///       summary: |
///         Retrieves all the domains for this namespace, with basic info
///       tags: ["Miscellaneous"]
///       responses:
///         200:
///           description: Successful response
///           schema:
///             $ref: '#/definitions/DomainList'
/// </example>
ClassMethod GetDomains(namespace As %String) As %Status
{
	set tSC = $$$OK
	$$$IKRESTINITDEBUG
	try {
		
		set tResult = { "domains": [] }
		
		set tSQLResult = ##class(%SQL.Statement).%ExecDirect(,"SELECT ID FROM %iKnow.""Domain""")
		while tSQLResult.%Next() {
			set tDomain = ##class(%iKnow.Domain).%OpenId(tSQLResult.%Get("ID"))
			set tJSON = { "id" : (tSQLResult.%Get("ID")), "name" : (tDomain.Name), "version" : (tDomain.Version) }
			set:tDomain.DefinitionClass'="" tJSON.definitionClass = tDomain.DefinitionClass
			set tJSON.sourceCount = ##class(%iKnow.Queries.SourceAPI).GetCountByDomain(tDomain.Id)
			do tResult.domains.%Push(tJSON)
		}
		
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit ..%ProcessResult(tSC, $g(tResult))
}

/// <example language="swagger">
///       summary: |
///         Retrieve more detailed information about an individual domain
///       tags: ["Miscellaneous"]
///       parameters:
///         - $ref: '#/parameters/domainParam'
///       responses:
///         200:
///           description: Successful response
///           schema:
///             $ref: '#/definitions/DomainDetails'
/// </example>
ClassMethod GetDomainDetails(namespace As %String, pDomainId As %Integer) As %Status
{
	set tSC = $$$OK
	$$$IKRESTINITDEBUG
	try {
		do ..ResolveDomainId(.pDomainId)
		set tDomain = ##class(%iKnow.Domain).%OpenId(pDomainId)
		if (tDomain="") { set tSC = $$$ERROR($$$IKNoDomainWithId,pDomainId) quit }
		
		set tResult = { "id": (pDomainId), "name": (tDomain.Name), "parameters": {}, "metadata": [] }
		do tDomain.GetParameters(.tParams)
		set tName = ""
		for {
			set tName = $order(tParams(tName),1,tValue)
			quit:tName=""
			do tResult.parameters.%Set(tName, tValue)
		}
		
		set tSC = ##class(%iKnow.Queries.MetadataAPI).GetFields(.tFields, pDomainId, 1)
		quit:$$$ISERR(tSC)
		set i=""
		for {
			set i = $order(tFields(i),1,tFieldData)
			quit:i=""
			
			set tField = { "id": (+$lg(tFieldData,1)), "name": ($lg(tFieldData,2)), "operators": [] }
			set ptr=0, tOperators=$lg(tFieldData,3)
			while $listnext(tOperators,ptr,tOp) {
				do tField.operators.%Push(tOp)
			}
			set tField.dataType = $case($lg(tFieldData,4), $$$MDDTSTRING:"string", $$$MDDTNUMBER:"number", $$$MDDTDATE:"date")
			set tField.storage = $case($lg(tFieldData,5), $$$MDSTNORMAL:"normal", $$$MDSTBITMAP:"bitmap", $$$MDSTCOMPRESS:"compressed", $$$MDSTCOMPRESSBITMAP:"bitmapCompressed")
			set tField.caseSensitive = +$lg(tFieldData,6)
			set tField.hidden = +$lg(tFieldData,9)
			
			if tField.storage'="normal" {
				set tField.values = []
				set tSC = ##class(%iKnow.Queries.MetadataAPI).GetFieldValuesById(.tValues, pDomainId, tField.id, 0, 0)
				quit:$$$ISERR(tSC)
				set j=""
				for {
					set j = $order(tValues(j),1,tValue)
					quit:j=""
					do tField.values.%Push($lg(tValue))
				}
			}
			
			do tResult.metadata.%Push(tField)
		}
		
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit ..%ProcessResult(tSC, $g(tResult))
}

/// Simplified version of <method>GetConfigurations</method> for HTTP GET requests
/// <example language="swagger">
///       summary: |
///         Retrieves all the configurations for this namespace, with basic info
///       tags: ["Miscellaneous"]
///       responses:
///         200:
///           description: Successful response
///           schema: 
///             $ref: '#/definitions/ConfigurationList'
/// </example>
ClassMethod GetConfigurationsGET(namespace As %String) As %Status [ Internal ]
{
	quit ..GetConfigurations(namespace)
}

/// <example language="swagger">
///       summary: |
///         Retrieves all the configurations for this namespace, with basic info
///       tags: ["Miscellaneous"]
///       parameters:
///         - name: RequestBody
///           description: additional parameters to configure this query
///           in: body
///           required: false
///           schema:
///             type: object
///             properties:
///               includeUserDictionaryContents:
///                 type: boolean
///                 description: Whether or not to include user dictionary contents
///                 default: false
///                 format: integer
///       responses:
///         200:
///           description: Successful response
///           schema: 
///             $ref: '#/definitions/ConfigurationList'
/// </example>
ClassMethod GetConfigurations(namespace As %String) As %Status
{
	set tSC = $$$OK
	$$$IKRESTINITDEBUG
	try {
		
		set tResult = { "configurations": [] }
		
		set tSQLResult = ##class(%SQL.Statement).%ExecDirect(,"SELECT ID FROM %iKnow.Configuration")
		while tSQLResult.%Next() {
			set tConfig = ##class(%iKnow.Configuration).%OpenId(tSQLResult.%Get("ID"))
			set tJSON = { "id" : (tSQLResult.%Get("ID")), "name" : (tConfig.Name), "languages" : [] }
			for i = 1:1:$ll(tConfig.Languages) {
				do tJSON.languages.%Push($lg(tConfig.Languages,i))
			}
			if (tConfig.UserDictionary'="") {
				set tJSON.userDictionary = { "name" : (tConfig.UserDictionary) }
				if (%request.Content.includeUserDictionaryContents) {
					#dim tUD As %iKnow.UserDictionary
					set tUD = ##class(%iKnow.UserDictionary).OpenByName(tConfig.UserDictionary)
					set:tUD.Description'="" tJSON.userDictionary.description = tUD.Description
					do tUD.GetEntries(.tEntries)
					set tJSON.userDictionary.entries = []
					set i = ""
					for {
						set i = $order(tEntries(i),1,tEntry)
						quit:i=""
						set tFrom = $lg(tEntry,1)
						if $e(tFrom)="@" {
							do tJSON.userDictionary.entries.%Push({"string":($e(tFrom,2,*-1)), "label":($lg(tEntry,2))})
						} else {
							do tJSON.userDictionary.entries.%Push({"string":(tFrom), "rewrite":($lg(tEntry,2))})
						}
					}
				}
				set:tConfig.MaxConceptLength tJSON.maxConceptLength = tConfig.MaxConceptLength
			}
			do tResult.configurations.%Push(tJSON)
		}
		
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit ..%ProcessResult(tSC, $g(tResult))
}

/// Simplified version of <method>GetSources</method> for HTTP GET requests
/// <example language="swagger">
///       summary: |
///         Retrieves all sources matching the supplied filter
///       tags: ["Sources"]
///       parameters:
///         - $ref: '#/parameters/domainParam'
///                 
///       responses:
///         200:
///           description: Successful response
///           schema: 
///             $ref: '#/definitions/SourceList'
/// </example>
ClassMethod GetSourcesGET(namespace As %String, pDomainId As %Integer) As %Status [ Internal ]
{
	quit ..GetSources(namespace,pDomainId)
}

/// <example language="swagger">
///       summary: |
///         Retrieves all sources matching the supplied filter
///       tags: ["Sources"]
///       parameters:
///         - $ref: '#/parameters/domainParam'
///         - name: RequestBody
///           description: JSON object with a list of query-specific arguments
///           in: body
///           schema:
///             type: object
///             properties:
///               page:
///                 $ref: '#/definitions/PageNumber'
///               pageSize:
///                 $ref: '#/definitions/PageSize'
///               filter:
///                 $ref: '#/definitions/Filter'
///               highlight:
///                 $ref: '#/definitions/Highlighting'
///               includeMetadata:
///                 description: whether or not to include metadata for each retrieved source
///                 type: boolean
///                 default: 1
///                 format: integer
///               includeSnippets:
///                 description: if set to a nonzero value, a snippet of the designated length (in sentences) will be retrieved for each source
///                 type: integer
///                 default: {{{SNIPPETSIZE}}}
///               includeCount:
///                 $ref: '#/definitions/IncludeCount'
///               countOnly:
///                 $ref: '#/definitions/CountOnly'
///                 
///       responses:
///         200:
///           description: Successful response
///           schema: 
///             $ref: '#/definitions/SourceList'
/// </example>
ClassMethod GetSources(namespace As %String, pDomainId As %Integer) As %Status
{
	set tSC = $$$OK
	$$$IKRESTINITDEBUG
	try {
		do ..ResolveDomainId(.pDomainId)
		set:'%request.Content.%IsDefined("includeMetadata") %request.Content.includeMetadata = 1
		set:'%request.Content.%IsDefined("includeSnippets") %request.Content.includeSnippets = ..#SNIPPETSIZE
		
		set tResult = {}
		
		set tSC = ..ParseArgs(pDomainId, .tPage, .tPageSize, .tFilter)
		quit:$$$ISERR(tSC)
		
		// BDB753
		if (%request.Content.includeCount || %request.Content.countOnly) {
			set tCount = ##class(%iKnow.Queries.SourceAPI).GetCountByDomain(pDomainId, tFilter, .tSC)
			quit:$$$ISERR(tSC)
			set tResult.count = tCount
		}
		quit:%request.Content.countOnly
		
		set tResult.sources = []
		
		set tSC = ..ParseHighlight(.tHighlight)
		quit:$$$ISERR(tSC)
		
		set tSC = ##class(%iKnow.Queries.SourceAPI).GetByDomain(.tSources, pDomainId, tPage, tPageSize, tFilter)
		quit:$$$ISERR(tSC)
		
		if (%request.Content.includeMetadata) {
			$$$IKRESTSTARTTIMER(metadata)
			set tSC = ##class(%iKnow.Queries.MetadataAPI).GetFields(.tFields, pDomainId)
			quit:$$$ISERR(tSC)
			set i=""
			for {
				set i = $order(tFields(i),1,tFieldData)
				quit:i=""
				set tDataTypes($lg(tFieldData,2)) = $lg(tFieldData,4)
			}
			kill tFields
			$$$IKRESTSTOPTIMER(metadata)
		}
		
		set i=""
		for {
			set i = $order(tSources(i), 1, tSrcData)
			quit:i=""
			
			set tJSON = {"id": (+$lg(tSrcData,1)), "extId": ($lg(tSrcData,2)) }
			
			if (%request.Content.includeMetadata) {
				$$$IKRESTSTARTTIMER(metadata)
				set tJSON.metadata = {}
				set tSC = ##class(%iKnow.Queries.MetadataAPI).GetValuesById(.tMetadata, pDomainId, tJSON.id)
				quit:$$$ISERR(tSC)
				set j=""
				for {
					set j = $order(tMetadata(j),1,tMetadataData)
					quit:j=""
					set tName = $lg(tMetadataData,2), tValue = $lg(tMetadataData,3)
					if (tDataTypes(tName)="NUMBER") {
						set tValue = +tValue
					} elseif (tDataTypes(tName)="DATE") {
						set tValue = $zdt(tValue)
					}
					do tJSON.metadata.%Set(tName, tValue)
				}
				$$$IKRESTSTOPTIMER(metadata)
			}
			
			if (%request.Content.includeSnippets) {
				$$$IKRESTSTARTTIMER(snippets)
				set tSC = ##class(%iKnow.Queries.SourceAPI).GetSummary(.tSentences, pDomainId, tJSON.id, %request.Content.includeSnippets)
				quit:$$$ISERR(tSC)
				set j="", tPrevSentId=0, tText=""
				for {
					set j = $order(tSentences(j), 1, tSentData)
					quit:j=""
						
					set tSentId = $lg(tSentData,1)
					set:tText'="" tText = tText_" "
					set:tPrevSentId&&(tSentId>(tPrevSentId+1)) tText = tText_"... "
					
					set tText = tText _ $s($d(tHighlight):##class(%iKnow.Queries.SentenceAPI).GetHighlighted(pDomainId, tSentId, .tHighlight,,, .tSC), 1:$lg(tSentData,2))
					
					set tPrevSentId = tSentId
				}
				set tJSON.snippet = tText
				$$$IKRESTSTOPTIMER(snippets)
			}
			
			do tResult.sources.%Push(tJSON)
		}
		
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit ..%ProcessResult(tSC, $g(tResult))
}

/// Simplified version of <method>GetSimilarSources</method> for HTTP GET requests
/// <example language="swagger">
///       summary: |
///         Retrieves all sources similar to a seed source
///       tags: ["Sources"]
///       parameters:
///         - $ref: '#/parameters/domainParam'
///         - $ref: '#/parameters/sourceParam'
///                 
///       responses:
///         200:
///           description: Successful response
///           schema:
///             allOf:
///               - $ref: '#/definitions/SourceList'
///               - type: object
///                 properties:
///                   score:
///                     type: number
///                     description: score expressing the similarity between this record and the seed document
///                   percentageMatched:
///                     type: number
///                   percentageNew:
///                     type: number
///                   numberOfEntitiesInRefSource:
///                     type: integer
///                   numberOfEntitiesInCommon:
///                     type: integer
///                   numberOfEntitiesInThisSource:
///                     type: integer
/// </example>
ClassMethod GetSimilarSourcesGET(namespace As %String, pDomainId As %Integer, pSourceId As %Integer) As %Status [ Internal ]
{
	quit ..GetSimilarSources(namespace, pDomainId, pSourceId)
}

/// <example language="swagger">
///       summary: |
///         Retrieves all sources similar to a seed source
///       tags: ["Sources"]
///       parameters:
///         - $ref: '#/parameters/domainParam'
///         - $ref: '#/parameters/sourceParam'
///         - name: RequestBody
///           description: JSON object with a list of query-specific arguments
///           in: body
///           schema:
///             type: object
///             properties:
///               page:
///                 $ref: '#/definitions/PageNumber'
///               pageSize:
///                 $ref: '#/definitions/PageSize'
///               filter:
///                 $ref: '#/definitions/Filter'
///               highlight:
///                 $ref: '#/definitions/Highlighting'
///               algorithm:
///                 type: string
///                 enum: ["simple", "dominantEntities"]
///                 description: algorithm to use for calculating similar entities
///                 default: "simple"
///               parameters:
///                 type: array
///                 items:
///                   type: string
///                 description: additional parameters to tune the algorithm
///                 default: []
///               includeMetadata:
///                 description: whether or not to include metadata for each retrieved source
///                 type: boolean
///                 default: 1
///                 format: integer
///               includeSnippets:
///                 description: if set to a nonzero value, a snippet of the designated length (in sentences) will be retrieved for each source
///                 type: integer
///                 default: {{{SNIPPETSIZE}}}
///                 
///       responses:
///         200:
///           description: Successful response
///           schema:
///             allOf:
///               - $ref: '#/definitions/SourceList'
///               - type: object
///                 properties:
///                   score:
///                     type: number
///                     description: score expressing the similarity between this record and the seed document
///                   percentageMatched:
///                     type: number
///                   percentageNew:
///                     type: number
///                   numberOfEntitiesInRefSource:
///                     type: integer
///                   numberOfEntitiesInCommon:
///                     type: integer
///                   numberOfEntitiesInThisSource:
///                     type: integer
/// </example>
ClassMethod GetSimilarSources(namespace As %String, pDomainId As %Integer, pSourceId As %Integer) As %Status
{
	set tSC = $$$OK
	$$$IKRESTINITDEBUG
	try {
		do ..ResolveDomainId(.pDomainId)
		set:'%request.Content.%IsDefined("includeMetadata") %request.Content.includeMetadata = 1
		set:'%request.Content.%IsDefined("includeSnippets") %request.Content.includeSnippets = ..#SNIPPETSIZE
		
		set tAlgorithm = $s('%request.Content.%IsDefined("algorithm"):$$$SIMSRCSIMPLE, 1:$$$UPPER(%request.Content.algorithm))
		set tAlgorithmParameters = ..ParseList("parameters")
		
		set tResult = { "sources": [] }
		
		
		set tSC = ..ParseArgs(pDomainId, .tPage, .tPageSize, .tFilter,, .tBlacklist)
		quit:$$$ISERR(tSC)
		set tSC = ..ParseHighlight(.tHighlight)
		quit:$$$ISERR(tSC)
		
		set tSC = ##class(%iKnow.Queries.SourceAPI).GetSimilar(.tSources, pDomainId, pSourceId, tPage, tPageSize, tFilter, tAlgorithm, tAlgorithmParameters, tBlacklist)
		quit:$$$ISERR(tSC)
		
		if (%request.Content.includeMetadata) {
			$$$IKRESTSTARTTIMER(metadata)
			set tSC = ##class(%iKnow.Queries.MetadataAPI).GetFields(.tFields, pDomainId)
			quit:$$$ISERR(tSC)
			set i=""
			for {
				set i = $order(tFields(i),1,tFieldData)
				quit:i=""
				set tDataTypes($lg(tFieldData,2)) = $lg(tFieldData,4)
			}
			kill tFields
			$$$IKRESTSTOPTIMER(metadata)
		}
		
		set i=""
		for {
			set i = $order(tSources(i), 1, tSrcData)
			quit:i=""
			
			set tJSON = {"id": (+$lg(tSrcData,1)), "extId": ($lg(tSrcData,2)), "score" : (+$lg(tSrcData,8)) }
			set tJSON.percentageMatched = +$lg(tSrcData,3)
			set tJSON.percentageNew = +$lg(tSrcData,4)
			if $lg(tAlgorithmParameters,1)="cc" {
				set tJSON.numberOfCRCsInRefSource = +$lg(tSrcData,5)
				set tJSON.numberOfCRCsInCommon = +$lg(tSrcData,6)
				set tJSON.numberOfCRCsInThisSource = +$lg(tSrcData,7)
			} elseif $lg(tAlgorithmParameters,1)="cc" {
				set tJSON.numberOfCCsInRefSource = +$lg(tSrcData,5)
				set tJSON.numberOfCCsInCommon = +$lg(tSrcData,6)
				set tJSON.numberOfCCsInThisSource = +$lg(tSrcData,7)
			} else {
				set tJSON.numberOfEntitiesInRefSource = +$lg(tSrcData,5)
				set tJSON.numberOfEntitiesInCommon = +$lg(tSrcData,6)
				set tJSON.numberOfEntitiesInThisSource = +$lg(tSrcData,7)
			}
						
			if (%request.Content.includeMetadata) {
				$$$IKRESTSTARTTIMER(metadata)
				set tJSON.metadata = {}
				set tSC = ##class(%iKnow.Queries.MetadataAPI).GetValuesById(.tMetadata, pDomainId, tJSON.id)
				quit:$$$ISERR(tSC)
				set j=""
				for {
					set j = $order(tMetadata(j),1,tMetadataData)
					quit:j=""
					set tName = $lg(tMetadataData,2), tValue = $lg(tMetadataData,3)
					if (tDataTypes(tName)="NUMBER") {
						set tValue = +tValue
					} elseif (tDataTypes(tName)="DATE") {
						set tValue = $zdt(tValue)
					}
					do tJSON.metadata.%Set(tName, tValue)
				}
				$$$IKRESTSTOPTIMER(metadata)
			}
			
			if (%request.Content.includeSnippets) {
				$$$IKRESTSTARTTIMER(snippets)
				set tSC = ##class(%iKnow.Queries.SourceAPI).GetSummary(.tSentences, pDomainId, tJSON.id, %request.Content.includeSnippets)
				quit:$$$ISERR(tSC)
				set j="", tPrevSentId=0, tText=""
				for {
					set j = $order(tSentences(j), 1, tSentData)
					quit:j=""
						
					set tSentId = $lg(tSentData,1)
					set:tText'="" tText = tText_" "
					set:tPrevSentId&&(tSentId>(tPrevSentId+1)) tText = tText_"... "
					
					set tText = tText _ $s($d(tHighlight):##class(%iKnow.Queries.SentenceAPI).GetHighlighted(pDomainId, tSentId, .tHighlight,,, .tSC), 1:$lg(tSentData,2))
					
					set tPrevSentId = tSentId
				}
				set tJSON.snippet = tText
				$$$IKRESTSTOPTIMER(snippets)
			}
			
			do tResult.sources.%Push(tJSON)
		}
		
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit ..%ProcessResult(tSC, $g(tResult))
}

/// Simplified version of <method>GetSourcesByEntity</method> for HTTP GET requests
/// <example language="swagger">
///       summary: |
///         Retrieves all sources containing the supplied entity
///       tags: ["Sources"]
///       parameters:
///         - $ref: '#/parameters/domainParam'
///         - name: entity
///           in: path
///           description: entity to look for.
///           type: string
///           required: true
///       responses:
///         200:
///           description: Successful response
///           schema: 
///             $ref: '#/definitions/SourceList'
/// </example>
ClassMethod GetSourcesByEntityGET(namespace As %String, pDomainId As %Integer, pEntity As %String = "") As %Status [ Internal ]
{
	quit ..GetSourcesByEntity(namespace, pDomainId, pEntity)
}

/// Simplified version of <method>GetSourcesByEntityPOST</method> for HTTP POST requests
/// <example language="swagger">
///       summary: |
///         Retrieves all sources containing the supplied entity
///       tags: ["Sources"]
///       parameters:
///         - $ref: '#/parameters/domainParam'
///         - name: RequestBody
///           description: JSON object with a list of query-specific arguments
///           in: body
///           required: true
///           schema:
///             type: object
///             required: ["entity"]
///             properties:
///               entity:
///                 type: array
///                 items:
///                   type: string
///                 description: |
///                   the entity or list of entities to query for
///                 default: "tree house"
///               page:
///                 $ref: '#/definitions/PageNumber'
///               pageSize:
///                 $ref: '#/definitions/PageSize'
///               filter:
///                 $ref: '#/definitions/Filter'
///               highlight:
///                 $ref: '#/definitions/Highlighting'
///               includeMetadata:
///                 description: whether or not to include metadata for each retrieved source
///                 type: boolean
///                 default: 1
///                 format: integer
///               includeSnippets:
///                 description: if set to true, a snippet made up of all sentences containing the designated entities will be retrieved for each source
///                 type: boolean
///                 default: 1
///                 format: integer
///               actualFormOnly:
///                 type: boolean
///                 format: integer
///                 description: when this domain supports stemming, set to true to restrict to the supplied actual form only
///                 default: 0
///               setOperation:
///                 type: string
///                 enum: ["union", "intersect"]
///                 description: when supplying multiple entities, controls how the results for each entity should be combined
///               includeCount:
///                 $ref: '#/definitions/IncludeCount'
///               countOnly:
///                 $ref: '#/definitions/CountOnly'
///                 
///       responses:
///         200:
///           description: Successful response
///           schema: 
///             $ref: '#/definitions/SourceList'
/// </example>
ClassMethod GetSourcesByEntityPOST(namespace As %String, pDomainId As %Integer) As %Status [ Internal ]
{
	quit ..GetSourcesByEntity(namespace, pDomainId)
}

/// <example language="swagger">
///       summary: |
///         Retrieves all sources containing the supplied entity
///       tags: ["Sources"]
///       parameters:
///         - $ref: '#/parameters/domainParam'
///         - name: entity
///           in: path
///           description: entity to look for. If supplied in the request object, that value will take precedence over the path parameter
///           type: string
///           required: true
///         - name: RequestBody
///           description: JSON object with a list of query-specific arguments
///           in: body
///           schema:
///             type: object
///             properties:
///               entity:
///                 type: array
///                 items:
///                   type: string
///                 description: |
///                   if supplied, overwrites the value of the "entity" path parameter
///                 default: ""
///               page:
///                 $ref: '#/definitions/PageNumber'
///               pageSize:
///                 $ref: '#/definitions/PageSize'
///               filter:
///                 $ref: '#/definitions/Filter'
///               highlight:
///                 $ref: '#/definitions/Highlighting'
///               includeMetadata:
///                 description: whether or not to include metadata for each retrieved source
///                 type: boolean
///                 default: 1
///                 format: integer
///               includeSnippets:
///                 description: if set to true, a snippet made up of all sentences containing the designated entities will be retrieved for each source
///                 type: boolean
///                 default: 1
///                 format: integer
///               actualFormOnly:
///                 type: boolean
///                 format: integer
///                 description: when this domain supports stemming, set to true to restrict to the supplied actual form only
///                 default: 0
///               setOperation:
///                 type: string
///                 enum: ["union", "intersect"]
///                 description: when supplying multiple entities, controls how the results for each entity should be combined
///               includeCount:
///                 $ref: '#/definitions/IncludeCount'
///               countOnly:
///                 $ref: '#/definitions/CountOnly'
///                 
///       responses:
///         200:
///           description: Successful response
///           schema: 
///             $ref: '#/definitions/SourceList'
/// </example>
ClassMethod GetSourcesByEntity(namespace As %String, pDomainId As %Integer, pEntity As %String = "") As %Status
{
	set tSC = $$$OK
	$$$IKRESTINITDEBUG
	try {
		do ..ResolveDomainId(.pDomainId)
		set:'%request.Content.%IsDefined("includeMetadata") %request.Content.includeMetadata = 1
		set:'%request.Content.%IsDefined("includeSnippets") %request.Content.includeSnippets = ..#SNIPPETSIZE
		set tSetOp = $s($$$LOWER(%request.Content.setOperation)="intersect":$$$INTERSECT, 1:$$$UNION)
		
		set tResult = { }
		
		set pEntity = ..ParseList("entity", $g(pEntity))
		
		set tSC = ..ParseArgs(pDomainId, .tPage, .tPageSize, .tFilter)
		quit:$$$ISERR(tSC)
		
		// BDB753
		if (%request.Content.includeCount || %request.Content.countOnly) {
			set tCount = ##class(%iKnow.Queries.SourceAPI).GetCountByEntities(pDomainId, pEntity, tFilter, tSetOp, .tSC, %request.Content.actualFormOnly)
			quit:$$$ISERR(tSC)
			set tResult.count = tCount
		}
		quit:%request.Content.countOnly
		
		set tResult.sources = []
		set tSC = ..ParseHighlight(.tHighlight)
		quit:$$$ISERR(tSC)
		
		set tSC = ##class(%iKnow.Queries.SourceAPI).GetByEntities(.tSources, pDomainId, pEntity, tPage, tPageSize, tFilter, tSetOp,,, %request.Content.actualFormOnly)
		quit:$$$ISERR(tSC)
		
		if (%request.Content.includeMetadata) {
			$$$IKRESTSTARTTIMER(metadata)
			set tSC = ##class(%iKnow.Queries.MetadataAPI).GetFields(.tFields, pDomainId)
			quit:$$$ISERR(tSC)
			set i=""
			for {
				set i = $order(tFields(i),1,tFieldData)
				quit:i=""
				set tDataTypes($lg(tFieldData,2)) = $lg(tFieldData,4)
			}
			kill tFields
			$$$IKRESTSTOPTIMER(metadata)
		}
		
		set i=""
		for {
			set i = $order(tSources(i), 1, tSrcData)
			quit:i=""
			
			set tJSON = {"id": (+$lg(tSrcData,1)), "extId": ($lg(tSrcData,2)) }
			
			if (%request.Content.includeMetadata) {
				$$$IKRESTSTARTTIMER(metadata)
				set tJSON.metadata = {}
				set tSC = ##class(%iKnow.Queries.MetadataAPI).GetValuesById(.tMetadata, pDomainId, tJSON.id)
				quit:$$$ISERR(tSC)
				set j=""
				for {
					set j = $order(tMetadata(j),1,tMetadataData)
					quit:j=""
					set tName = $lg(tMetadataData,2), tValue = $lg(tMetadataData,3)
					if (tDataTypes(tName)="NUMBER") {
						set tValue = +tValue
					} elseif (tDataTypes(tName)="DATE") {
						set tValue = $zdt(tValue)
					}
					do tJSON.metadata.%Set(tName, tValue)
				}
				$$$IKRESTSTOPTIMER(metadata)
			}
			
			if (%request.Content.includeSnippets) {
				$$$IKRESTSTARTTIMER(snippets)
				set tSC = ##class(%iKnow.Queries.SentenceAPI).GetByEntities(.tSentences, pDomainId, pEntity, $lb(tJSON.id), 1, %request.Content.includeSnippets, $$$UNION, %request.Content.actualFormOnly)
				quit:$$$ISERR(tSC)
				set j="", tPrevSentId=0, tText=""
				for {
					set j = $order(tSentences(j), 1, tSentData)
					quit:j=""
						
					set tSentId = $lg(tSentData,3)
					set:tText'="" tText = tText_" "
					set:tPrevSentId&&(tSentId>(tPrevSentId+1)) tText = tText_"... "
					
					set tText = tText _ $s($d(tHighlight):##class(%iKnow.Queries.SentenceAPI).GetHighlighted(pDomainId, tSentId, .tHighlight,,, .tSC), 1:$lg(tSentData,4))
					
					set tPrevSentId = tSentId
				}
				set tJSON.snippet = tText
				$$$IKRESTSTOPTIMER(snippets)
			}
			
			do tResult.sources.%Push(tJSON)
		}
		
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit ..%ProcessResult(tSC, $g(tResult))
}

/// Simplified version of <method>GetSourcesByCRC</method> for HTTP GET requests
/// <example language="swagger">
///       summary: |
///         Retrieves all sources containing the supplied CRC
///       tags: ["Sources"]
///       parameters:
///         - $ref: '#/parameters/domainParam'
///         - name: crc
///           in: path
///           description: CRC to look for, as a colon-separated sequence of master, relation and slave. 
///           type: string
///           required: true
///           #example: john:likes:bananas
///       responses:
///         200:
///           description: Successful response
///           schema: 
///             $ref: '#/definitions/SourceList'
/// </example>
ClassMethod GetSourcesByCRCGET(namespace As %String, pDomainId As %Integer, pCRC As %String = "") As %Status [ Internal ]
{
	quit ..GetSourcesByCRC(namespace, pDomainId, pCRC)
}

/// Simplified version of <method>GetSourcesByCRC</method> for HTTP POST requests
/// <example language="swagger">
///       summary: |
///         Retrieves all sources containing the supplied CRC
///       tags: ["Sources"]
///       parameters:
///         - $ref: '#/parameters/domainParam'
///         - name: RequestBody
///           description: JSON object with a list of query-specific arguments
///           in: body
///           required: true
///           schema:
///             type: object
///             required: ["crc"]
///             properties:
///               crc:
///                 type: array
///                 items:
///                   $ref: '#/definitions/CRC'
///                 description: |
///                   the CRC to look for
///               page:
///                 $ref: '#/definitions/PageNumber'
///               pageSize:
///                 $ref: '#/definitions/PageSize'
///               filter:
///                 $ref: '#/definitions/Filter'
///               highlight:
///                 $ref: '#/definitions/Highlighting'
///               includeMetadata:
///                 description: whether or not to include metadata for each retrieved source
///                 type: boolean
///                 default: 1
///                 format: integer
///               includeSnippets:
///                 description: if set to true, a snippet made up of all the sentences containing the designated CRCs will be retrieved for each source
///                 type: boolean
///                 default: 1
///                 format: integer
///               setOperation:
///                 type: string
///                 enum: ["union", "intersect"]
///                 description: when supplying multiple entities, controls how the results for each entity should be combined
///               includeCount:
///                 $ref: '#/definitions/IncludeCount'
///               countOnly:
///                 $ref: '#/definitions/CountOnly'
///                 
///       responses:
///         200:
///           description: Successful response
///           schema: 
///             $ref: '#/definitions/SourceList'
/// </example>
ClassMethod GetSourcesByCRCPOST(namespace As %String, pDomainId As %Integer) As %Status [ Internal ]
{
	quit ..GetSourcesByCRC(namespace, pDomainId)
}

/// <example language="swagger">
///       summary: |
///         Retrieves all sources containing the supplied CRC
///       tags: ["Sources"]
///       parameters:
///         - $ref: '#/parameters/domainParam'
///         - name: crc
///           in: path
///           description: CRC to look for, as a colon-separated sequence of master, relation and slave. If supplied in the request object, that value will take precedence over the path parameter
///           type: string
///           required: true
///           #example: john:likes:bananas
///         - name: RequestBody
///           description: JSON object with a list of query-specific arguments
///           in: body
///           schema:
///             type: object
///             properties:
///               crc:
///                 type: array
///                 items:
///                   $ref: '#/definitions/CRC'
///                 description: |
///                   if supplied, overwrites the value of the "crc" path parameter
///                 default: ""
///               page:
///                 $ref: '#/definitions/PageNumber'
///               pageSize:
///                 $ref: '#/definitions/PageSize'
///               filter:
///                 $ref: '#/definitions/Filter'
///               highlight:
///                 $ref: '#/definitions/Highlighting'
///               includeMetadata:
///                 description: whether or not to include metadata for each retrieved source
///                 type: boolean
///                 default: 1
///                 format: integer
///               includeSnippets:
///                 description: if set to true, a snippet made up of all the sentences containing the designated CRCs will be retrieved for each source
///                 type: boolean
///                 default: 1
///                 format: integer
///               setOperation:
///                 type: string
///                 enum: ["union", "intersect"]
///                 description: when supplying multiple entities, controls how the results for each entity should be combined
///               includeCount:
///                 $ref: '#/definitions/IncludeCount'
///               countOnly:
///                 $ref: '#/definitions/CountOnly'
///                 
///       responses:
///         200:
///           description: Successful response
///           schema: 
///             $ref: '#/definitions/SourceList'
/// </example>
ClassMethod GetSourcesByCRC(namespace As %String, pDomainId As %Integer, pCRC As %String = "") As %Status
{
	set tSC = $$$OK
	$$$IKRESTINITDEBUG
	try {
		do ..ResolveDomainId(.pDomainId)
		set:'%request.Content.%IsDefined("includeMetadata") %request.Content.includeMetadata = 1
		set:'%request.Content.%IsDefined("includeSnippets") %request.Content.includeSnippets = ..#SNIPPETSIZE
		set tSetOp = $s($$$LOWER(%request.Content.setOperation)="intersect":$$$INTERSECT, 1:$$$UNION)
		
		set tResult = {}
		
		
		set tUseWildcards = 0, pCRC = $g(pCRC)
		if %request.Content.%IsDefined("crc") {
			if %request.Content.crc.%IsDefined("master") || %request.Content.crc.%IsDefined("relation") || %request.Content.crc.%IsDefined("slave") {
				set pCRC = $lb(%request.Content.crc.master, %request.Content.crc.relation, %request.Content.crc.slave)
				for i = 1:1:3 {
					if $lg(pCRC,i)="" { set $li(pCRC,i)="*", tUseWildcards=1 }
					elseif $lg(pCRC,i)="*" { set tUseWildcards=1 }
				}
			} else { // array
				set tIterator = %request.Content.entity.%GetIterator()
				while tIterator.%GetNext(,.tCRC) {
					set pCRC = pCRC_$lb($lb(tCRC.master, tCRC.relation, tCRC.slave))
				}
			}
		} else {
			set pCRC = $lfs($tr(pCRC,":;|~",",,,,"),",")
			for i = 1:1:3 {
				if $lg(pCRC,i)="" { set $li(pCRC,i)="*", tUseWildcards=1 }
				elseif $lg(pCRC,i)="*" { set tUseWildcards=1 }
			}
		}
		
		set tSC = ..ParseArgs(pDomainId, .tPage, .tPageSize, .tFilter)
		quit:$$$ISERR(tSC)
		
		// BDB753
		if (%request.Content.includeCount || %request.Content.countOnly) {
			if (tUseWildcards) {
				set tCount = ##class(%iKnow.Queries.SourceAPI).GetCountByCrcMask(pDomainId, $lg(pCRC,1), $lg(pCRC,2), $lg(pCRC,3), tFilter, .tSC, %request.Content.actualFormOnly)
			} else {
				set tCount = ##class(%iKnow.Queries.SourceAPI).GetCountByCrcs(pDomainId, pCRC, tFilter, tSetOp, .tSC)
			}
			quit:$$$ISERR(tSC)
			set tResult.count = tCount
		}
		quit:%request.Content.countOnly
		
		set tResult.sources = []
		set tSC = ..ParseHighlight(.tHighlight)
		quit:$$$ISERR(tSC)
		
		if (tUseWildcards) {
			set tSC = ##class(%iKnow.Queries.SourceAPI).GetByCrcMask(.tSources, pDomainId, $lg(pCRC,1), $lg(pCRC,2), $lg(pCRC,3), tPage, tPageSize, tFilter,, %request.Content.actualFormOnly)
			quit:$$$ISERR(tSC)
		} else {
			set tSC = ##class(%iKnow.Queries.SourceAPI).GetByCrcs(.tSources, pDomainId, pCRC, tPage, tPageSize, tFilter, tSetOp)
			quit:$$$ISERR(tSC)
		}
		
		if (%request.Content.includeMetadata) {
			$$$IKRESTSTARTTIMER(metadata)
			set tSC = ##class(%iKnow.Queries.MetadataAPI).GetFields(.tFields, pDomainId)
			quit:$$$ISERR(tSC)
			set i=""
			for {
				set i = $order(tFields(i),1,tFieldData)
				quit:i=""
				set tDataTypes($lg(tFieldData,2)) = $lg(tFieldData,4)
			}
			kill tFields
			$$$IKRESTSTOPTIMER(metadata)
		}
		
		set i=""
		for {
			set i = $order(tSources(i), 1, tSrcData)
			quit:i=""
			
			set tJSON = {"id": (+$lg(tSrcData,1)), "extId": ($lg(tSrcData,2)) }
			
			if (%request.Content.includeMetadata) {
				$$$IKRESTSTARTTIMER(metadata)
				set tJSON.metadata = {}
				set tSC = ##class(%iKnow.Queries.MetadataAPI).GetValuesById(.tMetadata, pDomainId, tJSON.id)
				quit:$$$ISERR(tSC)
				set j=""
				for {
					set j = $order(tMetadata(j),1,tMetadataData)
					quit:j=""
					set tName = $lg(tMetadataData,2), tValue = $lg(tMetadataData,3)
					if (tDataTypes(tName)="NUMBER") {
						set tValue = +tValue
					} elseif (tDataTypes(tName)="DATE") {
						set tValue = $zdt(tValue)
					}
					do tJSON.metadata.%Set(tName, tValue)
				}
				$$$IKRESTSTOPTIMER(metadata)
			}
			
			if (%request.Content.includeSnippets) {
				$$$IKRESTSTARTTIMER(snippets)
				if tUseWildcards {
					set tSC = ##class(%iKnow.Queries.SentenceAPI).GetByCrcMask(.tSentences, pDomainId, $lg(pCRC,1), $lg(pCRC,2), $lg(pCRC,3), $lb(tJSON.id), 1, %request.Content.includeSnippets, $$$UNION, %request.Content.actualFormOnly)
					quit:$$$ISERR(tSC)
				} else {
					set tSC = ##class(%iKnow.Queries.SentenceAPI).GetByCrcs(.tSentences, pDomainId, pCRC, $lb(tJSON.id), 1, %request.Content.includeSnippets, $$$UNION)
					quit:$$$ISERR(tSC)
				}
				set j="", tPrevSentId=0, tText=""
				for {
					set j = $order(tSentences(j), 1, tSentData)
					quit:j=""
						
					set tSentId = $lg(tSentData,3)
					set:tText'="" tText = tText_" "
					set:tPrevSentId&&(tSentId>(tPrevSentId+1)) tText = tText_"... "
					
					set tText = tText _ $s($d(tHighlight):##class(%iKnow.Queries.SentenceAPI).GetHighlighted(pDomainId, tSentId, .tHighlight,,, .tSC), 1:$lg(tSentData,4))
					
					set tPrevSentId = tSentId
				}
				set tJSON.snippet = tText
				$$$IKRESTSTOPTIMER(snippets)
			}
			
			do tResult.sources.%Push(tJSON)
		}
		
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit ..%ProcessResult(tSC, $g(tResult))
}

/// Simplified version of <method>GetSourceDetails</method> for HTTP GET requests
/// <example language="swagger">
///       summary: |
///         Retrieves the details of a particular source
///       tags: ["Sources"]
///       parameters:
///         - $ref: '#/parameters/domainParam'
///         - $ref: '#/parameters/sourceParam'
///                 
///       responses:
///         200:
///           description: Successful response
///           schema: 
///             title: Source
///             type: object
///             properties:
///               text:
///                 type: string
///                 description: textual contents (optionally summarized) of this source
///               metadata:
///                 type: object
///                 description: metadata map for this source
///               virtual:
///                 type: boolean
///                 format: integer
///                 description: whether or not this is a virtual source
/// </example>
ClassMethod GetSourceDetailsGET(namespace As %String, pDomainId As %Integer, pSourceId As %Integer) As %Status [ Internal ]
{
	quit ..GetSourceDetails(namespace, pDomainId, pSourceId)
}

/// <example language="swagger">
///       summary: |
///         Retrieves the details of a particular source
///       tags: ["Sources"]
///       parameters:
///         - $ref: '#/parameters/domainParam'
///         - $ref: '#/parameters/sourceParam'
///         - name: RequestBody
///           description: JSON object with a list of query-specific arguments
///           in: body
///           schema:
///             type: object
///             properties:
///               includeMetadata:
///                 description: whether or not to include metadata for the designated source
///                 type: boolean
///                 default: 1
///                 format: integer
///               includeText:
///                 description: whether or not to include the full source text in the result
///                 type: boolean
///                 default: 1
///                 format: integer
///               summarize:
///                 description: if set, the text returned will be a summary of the full contents, measuring this many sentences
///                 type: number
///               virtual:
///                 description: if set to true, the source ID will be considered to refer to a virtual source
///                 type: boolean
///                 default: 0
///                 format: integer
///               highlight:
///                 $ref: '#/definitions/Highlighting'
///                 
///       responses:
///         200:
///           description: Successful response
///           schema: 
///             title: Source
///             type: object
///             properties:
///               text:
///                 type: string
///                 description: textual contents (optionally summarized) of this source
///               metadata:
///                 type: object
///                 description: metadata map for this source
///               virtual:
///                 type: boolean
///                 format: integer
///                 description: whether or not this is a virtual source
/// </example>
ClassMethod GetSourceDetails(namespace As %String, pDomainId As %Integer, pSourceId As %Integer) As %Status
{
	set tSC = $$$OK
	$$$IKRESTINITDEBUG
	try {
		do ..ResolveDomainId(.pDomainId)
		set:'%request.Content.%IsDefined("includeMetadata") %request.Content.includeMetadata = 1
		set:'%request.Content.%IsDefined("includeText") %request.Content.includeText = 1
		
		set:%request.Content.virtual pSourceId = -$zabs(pSourceId)
		$$$CHECKASRCIDEXISTSX(pDomainId,pSourceId,tSrcDetails,vSrcId,tSC)
		
		
		set tResult = { "virtual": (''vSrcId) }
		
		if (%request.Content.includeMetadata) && 'vSrcId {
			$$$IKRESTSTARTTIMER(metadata)
			set tSC = ##class(%iKnow.Queries.MetadataAPI).GetFields(.tFields, pDomainId, 1)
			quit:$$$ISERR(tSC)
			set i=""
			for {
				set i = $order(tFields(i),1,tFieldData)
				quit:i=""
				set tDataTypes($lg(tFieldData,2)) = $lg(tFieldData,4)
			}
			set tResult.metadata = {}
			
			set tSC = ##class(%iKnow.Queries.MetadataAPI).GetValuesById(.tMetadata, pDomainId, pSourceId, 1)
			quit:$$$ISERR(tSC)
			set j=""
			for {
				set j = $order(tMetadata(j),1,tMetadataData)
				quit:j=""
				set tName = $lg(tMetadataData,2), tValue = $lg(tMetadataData,3)
				if (tDataTypes(tName)="NUMBER") {
					set tValue = +tValue
				} elseif (tDataTypes(tName)="DATE") {
					set tValue = $zdt(tValue)
				}
				do tResult.metadata.%Set(tName, tValue)
			}
			$$$IKRESTSTOPTIMER(metadata)
		}
		
		if (%request.Content.includeText) {
			$$$IKRESTSTARTTIMER(text)
			set tSummarize = +%request.Content.summarize
			if 'tSummarize {
				set tSC = ##class(%iKnow.Queries.SentenceAPI).GetBySource(.tSentences, pDomainId, pSourceId, 0, 0)
				quit:$$$ISERR(tSC)
			} else {
				set tSC = ##class(%iKnow.Queries.SourceAPI).GetSummary(.tSentences, pDomainId, pSourceId, tSummarize)
				quit:$$$ISERR(tSC)
			}
			do ..ParseHighlight(.tHighlight)
			set i="", tText="", tPrevSentId=0
			for {
				set i = $order(tSentences(i),1,tSentData) 
				quit:i=""
				
				set tSentId = $lg(tSentData,1)
				set:tText'="" tText = tText_" "
				set:tPrevSentId&&(tSentId>(tPrevSentId+1)) tText = tText_"... "
				
				set tText = tText _ $s($d(tHighlight):##class(%iKnow.Queries.SentenceAPI).GetHighlighted(pDomainId, tSentId, .tHighlight, vSrcId,, .tSC), 1:$lg(tSentData,2))
				
				set tPrevSentId = tSentId
			}
			set tResult.text = tText
			$$$IKRESTSTOPTIMER(text)
		}
		
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit ..%ProcessResult(tSC, $g(tResult))
}

/// Simplified version of <method>GetEntities</method> for HTTP GET requests.
/// <example language="swagger">
///       summary: |
///         Retrieves the top entities for this domain
///       tags: ["Entities"]
///       parameters:
///         - $ref: '#/parameters/domainParam'
///                 
///       responses:
///         200:
///           description: Successful response
///           schema: 
///             title: EntityList
///             type: object
///             properties:
///               entities:
///                 type: array 
///                 items:
///                   title: Entity
///                   type: object
///                   required:
///                     - id
///                     - value
///                   properties:
///                     id:
///                       type: integer
///                       description: unique entity ID
///                     value:
///                       type: string
///                       description: entity value
///                     frequency:
///                       type: integer
///                       description: number of times the entity occurs in the result set
///                     spread:
///                       type: integer
///                       description: number of distinct sources the entity occurs in in the result set
///                     dominance:
///                       type: number
///                       description: relevance of the entity in this result set
///                     tfidf:
///                       type: number
///                       description: TFIDF-based metric expressing relevance of the entity in this result set
///                     bm25:
///                       type: number
///                       description: BM25-based metric expressing relevance of the entity in this result set
/// </example>
ClassMethod GetEntitiesGET(namespace As %String, pDomainId As %Integer) As %Status [ Internal ]
{
	quit ..GetEntities(namespace, pDomainId)
}

/// <example language="swagger">
///       summary: |
///         Retrieves the top entities for this domain
///       tags: ["Entities"]
///       parameters:
///         - $ref: '#/parameters/domainParam'
///         - name: RequestBody
///           description: JSON object with a list of query-specific arguments
///           in: body
///           schema:
///             type: object
///             properties:
///               page:
///                 $ref: '#/definitions/PageNumber'
///               pageSize:
///                 $ref: '#/definitions/PageSize'
///               filter:
///                 $ref: '#/definitions/Filter'
///               filterMode:
///                 $ref: '#/definitions/FilterMode'
///               blacklists:
///                 $ref: '#/definitions/Blacklists'
///               sortBy:
///                 description: criterion to use for retrieving the top entities
///                 type: string
///                 default: "domainDefault"
///                 example: "domainDefault"
///                 enum: ["frequency", "spread", "domainDefault", "dominance", "bm25", "tfidf"]
///               useStems:
///                 description: |
///                   retrieve stems rather than entities. (only available when the domain has stemming enabled and for certain sortBy values)
///                 type: integer
///                 default: 0
///                 format: integer
///               role:
///                 description: whether to retrieve top concepts, relationships or both (only available for certain sortBy values)
///                 type: string
///                 default: "concept"
///                 enum: ["concept", "relation", "any"]
///               includeMetrics:
///                 description: additional metrics to retrieve, on top of what is automatically retrieved based on the sortBy value
///                 type: array
///                 default: []
///                 items:
///                   type: string
///                   enum: ["frequency", "spread", "dominance", "tfidf"]
///               includeCount:
///                 $ref: '#/definitions/IncludeCount'
///               countOnly:
///                 $ref: '#/definitions/CountOnly'
///                 
///       responses:
///         200:
///           description: Successful response
///           schema: 
///             title: EntityList
///             type: object
///             properties:
///               entities:
///                 type: array 
///                 items:
///                   title: Entity
///                   type: object
///                   required:
///                     - id
///                     - value
///                   properties:
///                     id:
///                       type: integer
///                       description: unique entity ID
///                     value:
///                       type: string
///                       description: entity value
///                     frequency:
///                       type: integer
///                       description: number of times the entity occurs in the result set
///                     spread:
///                       type: integer
///                       description: number of distinct sources the entity occurs in in the result set
///                     dominance:
///                       type: number
///                       description: relevance of the entity in this result set
///                     tfidf:
///                       type: number
///                       description: TFIDF-based metric expressing relevance of the entity in this result set
///                     bm25:
///                       type: number
///                       description: BM25-based metric expressing relevance of the entity in this result set
///               count:
///                 type: integer
///                 description: total number of entities in this domain (if RequestBody.includeCount is true, ignoring page and pageSize)
/// </example>
ClassMethod GetEntities(namespace As %String, pDomainId As %Integer) As %Status
{
	set tSC = $$$OK
	$$$IKRESTINITDEBUG
	try {
		do ..ResolveDomainId(.pDomainId)
		set tSortBy = $s('%request.Content.%IsDefined("sortBy"):"domaindefault", 1:$$$LOWER(%request.Content.sortBy))
		set tUseStems = +%request.Content.useStems
		set tRole = $case($$$LOWER(%request.Content.role), "relation":$$$ENTTYPERELATION, "concept":$$$ENTTYPECONCEPT, "any":$$$ENTTYPEANY, :$$$ENTTYPECONCEPT)
		
		set tResult = { }
		
		
		set tSC = ..ParseArgs(pDomainId, .tPage, .tPageSize, .tFilter, .tFilterMode, .tBlackLists)
		quit:$$$ISERR(tSC)
		
		// BDB753
		if (%request.Content.includeCount || %request.Content.countOnly) {
			set tCount = ##class(%iKnow.Queries.EntityAPI).GetCountByDomain(pDomainId, tFilter, .tSC, tBlackLists,, tUseStems)
			quit:$$$ISERR(tSC)
			set tResult.count = tCount
		}
		quit:%request.Content.countOnly
		
		set tResult.entities = []
		
		if (tSortBy="domaindefault") || (tSortBy="frequency") || (tSortBy="spread") {
			
			set tSortMode = $case(tSortBy, "domaindefault":$$$SORTBYDOMAINDEFAULT, "frequency":$$$SORTBYFREQUENCY, "spread":$$$SORTBYSPREAD)
			set tSC = ##class(%iKnow.Queries.EntityAPI).GetTop(.tEntities, pDomainId, tPage, tPageSize, tFilter, tFilterMode, tSortMode, tRole,, tBlackLists, tUseStems)
			quit:$$$ISERR(tSC)
			
		} elseif (tSortBy="dominance") {
			
			if tRole=$$$ENTTYPEANY { set tSC = $$$ERROR($$$NotImplemented) quit } 
			set tDomRole = $s(tUseStems:$case(tRole,$$$ENTTYPECONCEPT:$$$SDSTEMCONCEPT, $$$ENTTYPERELATION:$$$SDSTEMRELATION), 1:$case(tRole,$$$ENTTYPECONCEPT:$$$SDCONCEPT, $$$ENTTYPERELATION:$$$SDRELATION))
			set tSC = ##class(%iKnow.Semantics.DominanceAPI).GetTop(.tEntities, pDomainId, tPage, tPageSize, tFilter,, tDomRole)
			quit:$$$ISERR(tSC)
			
		} elseif (tSortBy="bm25") {
			
			set tSC = ##class(%iKnow.Queries.EntityAPI).GetTopBM25(.tEntities, pDomainId, tPage, tPageSize, tFilter, tRole, tUseStems)
			quit:$$$ISERR(tSC)
			
		} elseif (tSortBy="tfidf") {
			
			set tSC = ##class(%iKnow.Queries.EntityAPI).GetTopTFIDF(.tEntities, pDomainId, tPage, tPageSize, tFilter, tRole, tUseStems)
			quit:$$$ISERR(tSC)
			
		} else {
			set tSC = $$$ERROR($$$NotImplemented)
			quit
		}
		
		set (tIncludeFrequency, tIncludeSpread, tIncludeDominance, tIncludeBM25, tIncludeTFIDF) = 0
		if $isobject(%request.Content.includeMetrics) {
			$$$IKRESTSTARTTIMER(additionalMetrics)
			set tIterator = %request.Content.includeMetrics.%GetIterator()
			while tIterator.%GetNext(,.tValue) {
				if (tValue="frequency") {
					set tIncludeFrequency = '$d(tSortMode)
				} elseif (tValue="spread") {
					set tIncludeSpread = '$d(tSortMode)
				//} elseif (tValue="bm25") {
				//	set tIncludeBM25 = (tSortBy'=tValue)
				} elseif (tValue="tfidf") {
					set tIncludeTFIDF = (tSortBy'=tValue)
					set tDocCount = ##class(%iKnow.Queries.SourceAPI).GetCountByDomain(pDomainId, tFilter)
				} elseif (tValue="dominance") {
					set tIncludeDominance = (tSortBy'=tValue)
					if tRole=$$$ENTTYPEANY { set tSC = $$$ERROR($$$NotImplemented) quit } 
					set tDomRole = $s(tUseStems:$case(tRole,$$$ENTTYPECONCEPT:$$$SDSTEMCONCEPT, $$$ENTTYPERELATION:$$$SDSTEMRELATION), 1:$case(tRole,$$$ENTTYPECONCEPT:$$$SDCONCEPT, $$$ENTTYPERELATION:$$$SDRELATION))
				}
			}
			$$$IKRESTSTOPTIMER(additionalMetrics)
		}
		
		set i=""
		for {
			set i = $order(tEntities(i), 1, tEntData) 
			quit:i=""
			
			set tJSON = { "id":(+$lg(tEntData,1)), "value":($lg(tEntData,2)) }
			if (tSortBy="dominance") {
				set tJSON.dominance = +$lg(tEntData,3)
			} elseif (tSortBy="bm25") {
				set tJSON.bm25 = +$lg(tEntData,3)
			} elseif (tSortBy="tfidf") {
				set tJSON.tfidf = +$lg(tEntData,3)
			} else {
				set tJSON.frequency = +$lg(tEntData,3)
				set tJSON.spread = +$lg(tEntData,4)
			}
			
			$$$IKRESTSTARTTIMER(additionalMetrics)
			set:tIncludeFrequency||tIncludeTFIDF tFreq = $s(tUseStems:##class(%iKnow.Queries.EntityAPI).GetStemFrequency(pDomainId, tJSON.id, tRole,, tFilter), 1:##class(%iKnow.Queries.EntityAPI).GetFrequency(pDomainId, tJSON.id, tRole,, tFilter))
			set:tIncludeFrequency tJSON.frequency = tFreq
			
			set:tIncludeSpread||tIncludeTFIDF tSpread = $s(tUseStems:##class(%iKnow.Queries.EntityAPI).GetStemSpread(pDomainId, tJSON.id, tRole, tFilter), 1:##class(%iKnow.Queries.EntityAPI).GetSpread(pDomainId, tJSON.id, tRole, tFilter))
			set:tIncludeSpread tJSON.spread = tSpread
			
			set:tIncludeDominance tJSON.dominance = ##class(%iKnow.Semantics.DominanceAPI).GetDomainValue(pDomainId, tJSON.id, tDomRole)
			
			set:tIncludeTFIDF tJSON.tfidf = +$justify(tFreq * $zlog((tDocCount - tSpread + 0.5) / (tSpread + 0.5)),"",4)
			$$$IKRESTSTOPTIMER(additionalMetrics)
			
			do tResult.entities.%Push(tJSON)
		}
		
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit ..%ProcessResult(tSC, $g(tResult))
}

/// Simplified version of <method>GetSimilarEntities</method> for HTTP GET requests
/// <example language="swagger">
///       summary: |
///         Retrieves entities similar to a seed string
///       tags: ["Entities"]
///       parameters:
///         - $ref: '#/parameters/domainParam'
///         - name: string
///           description: the seed string to find similar entities for
///           in: path
///           required: true
///           type: string
///                 
///       responses:
///         200:
///           description: Successful response
///           schema: 
///             $ref: '#/definitions/EntityList'
/// </example>
ClassMethod GetSimilarEntitiesGET(namespace As %String, pDomainId As %Integer, pString As %String = "") As %Status [ Internal ]
{
	quit ..GetSimilarEntities(namespace, pDomainId, pString)
}

/// Simplified version of <method>GetSimilarEntities</method> for HTTP POST requests.
/// <example language="swagger">
///       summary: |
///         Retrieves entities similar to a seed string
///       tags: ["Entities"]
///       parameters:
///         - $ref: '#/parameters/domainParam'
///         - name: RequestBody
///           description: JSON object with a list of query-specific arguments
///           in: body
///           required: true
///           schema:
///             type: object
///             required: ["string" ]
///             properties:
///               string:
///                 description: the seed string to find similar entities for
///                 type: string
///                 example: "tree"
///               page:
///                 $ref: '#/definitions/PageNumber'
///               pageSize:
///                 $ref: '#/definitions/PageSize'
///               filter:
///                 $ref: '#/definitions/Filter'
///               filterMode:
///                 $ref: '#/definitions/FilterMode'
///               blacklists:
///                 $ref: '#/definitions/Blacklists'
///               type:
///                 description: |
///                   method to calculate / retrieve similar entities. ("ngrams" requires the domain to be configured for it)
///                 type: string
///                 default: "domainDefault"
///                 example: "domainDefault"
///                 enum: ["domainDefault", "parts", "ngrams", "words"]
///               useStems:
///                 description: retrieve stems rather than entities. (only available when the domain has stemming enabled and for certain sortBy values)
///                 type: boolean
///                 default: 0
///                 format: integer
///               role:
///                 description: whether to retrieve top concepts, relationships or both (only available for certain sortBy values)
///                 type: string
///                 default: "any"
///                 example: "any"
///                 enum: ["concept", "relation", "any"]
///               includeCount:
///                 $ref: '#/definitions/IncludeCount'
///               countOnly:
///                 $ref: '#/definitions/CountOnly'
///                 
///       responses:
///         200:
///           description: Successful response
///           schema: 
///             $ref: '#/definitions/EntityList'
/// </example>
ClassMethod GetSimilarEntitiesPOST(namespace As %String, pDomainId As %Integer) As %Status [ Internal ]
{
	quit ..GetSimilarEntities(namespace, pDomainId)
}

/// <example language="swagger">
///       summary: |
///         Retrieves entities similar to a seed string
///       tags: ["Entities"]
///       parameters:
///         - $ref: '#/parameters/domainParam'
///         - name: string
///           description: the seed string to find similar entities for
///           in: path
///           required: true
///           type: string
///         - name: RequestBody
///           description: JSON object with a list of query-specific arguments
///           in: body
///           schema:
///             type: object
///             properties:
///               string:
///                 description: if set, overrides value of path parameter
///                 type: string
///                 default: ""
///                 example: ""
///               page:
///                 $ref: '#/definitions/PageNumber'
///               pageSize:
///                 $ref: '#/definitions/PageSize'
///               filter:
///                 $ref: '#/definitions/Filter'
///               filterMode:
///                 $ref: '#/definitions/FilterMode'
///               blacklists:
///                 $ref: '#/definitions/Blacklists'
///               type:
///                 description: |
///                   method to calculate / retrieve similar entities. ("ngrams" requires the domain to be configured for it)
///                 type: string
///                 default: "domainDefault"
///                 example: "domainDefault"
///                 enum: ["domainDefault", "parts", "ngrams", "words"]
///               useStems:
///                 description: retrieve stems rather than entities. (only available when the domain has stemming enabled and for certain sortBy values)
///                 type: boolean
///                 default: 0
///                 format: integer
///               role:
///                 description: whether to retrieve top concepts, relationships or both (only available for certain sortBy values)
///                 type: string
///                 default: "any"
///                 example: "any"
///                 enum: ["concept", "relation", "any"]
///               includeCount:
///                 $ref: '#/definitions/IncludeCount'
///               countOnly:
///                 $ref: '#/definitions/CountOnly'
///                 
///       responses:
///         200:
///           description: Successful response
///           schema: 
///             $ref: '#/definitions/EntityList'
/// </example>
ClassMethod GetSimilarEntities(namespace As %String, pDomainId As %Integer, pString As %String = "") As %Status
{
	set tSC = $$$OK
	$$$IKRESTINITDEBUG
	try {
		do ..ResolveDomainId(.pDomainId)
		set:'%request.Content.%IsDefined("type") %request.Content.type = "domainDefault"
		set tUseStems = +%request.Content.useStems
		set tRole = $case($$$LOWER(%request.Content.role), "relation":$$$ENTTYPERELATION, "concept":$$$ENTTYPECONCEPT, "any":$$$ENTTYPEANY, :$$$ENTTYPECONCEPT)
		set tSimilarMode = $case(%request.Content.type, "domainDefault":$$$USEDOMAINDEFAULT, "parts":$$$USEPARTS, "ngrams":$$$USENGRAMS, "words":$$$USEWORDS)
				
		set:%request.Content.%IsDefined("string") pString = %request.Content.string

		set tResult = { }
		
		set tSC = ..ParseArgs(pDomainId, .tPage, .tPageSize, .tFilter, .tFilterMode, .tBlackLists)
		quit:$$$ISERR(tSC)
		
		// BDB753
		if (%request.Content.includeCount || %request.Content.countOnly) {
			set tCounts = ##class(%iKnow.Queries.EntityAPI).GetSimilarCounts(pDomainId, pString, tFilter, tSimilarMode, tBlackLists, .tSC, tRole, tUseStems)
			quit:$$$ISERR(tSC)
			set tResult.count = $lg(tCounts,1)
		}
		quit:%request.Content.countOnly
		
		set tResult.entities = []
		
		set tSC = ##class(%iKnow.Queries.EntityAPI).GetSimilar(.tEntities, pDomainId, pString, tPage, tPageSize, tFilter, tFilterMode, tSimilarMode, tBlackLists, tRole, tUseStems)
		quit:$$$ISERR(tSC)
		
		set i=""
		for {
			set i = $order(tEntities(i), 1, tEntData) 
			quit:i=""
			
			set tJSON = { "id":(+$lg(tEntData,1)), "value":($lg(tEntData,2)), "frequency": (+$lg(tEntData,3)), "spread": (+$lg(tEntData,4)) }
			do tResult.entities.%Push(tJSON)
		}
		
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit ..%ProcessResult(tSC, $g(tResult))
}

/// Simplified version of <method>GetRelatedEntities</method> for HTTP GET requests
/// <example language="swagger">
///       summary: |
///         Retrieves entities related to a seed entity based on proximity or direct relationships
///       tags: ["Entities"]
///       parameters:
///         - $ref: '#/parameters/domainParam'
///         - name: entity
///           description: the seed entity to find related entities for
///           in: path
///           required: true
///           type: string
///                 
///       responses:
///         200:
///           description: Successful response
///           schema: 
///             $ref: '#/definitions/EntityList'
/// </example>
ClassMethod GetRelatedEntitiesGET(namespace As %String, pDomainId As %Integer, pEntity As %String = "") As %Status [ Internal ]
{
	quit ..GetRelatedEntities(namespace, pDomainId, pEntity)
}

/// Simplified version of <method>GetRelatedEntities</method> for HTTP POST requests
/// <example language="swagger">
///       summary: |
///         Retrieves entities related to a seed entity based on proximity or direct relationships
///       tags: ["Entities"]
///       parameters:
///         - $ref: '#/parameters/domainParam'
///         - name: RequestBody
///           description: JSON object with a list of query-specific arguments
///           in: body
///           required: true
///           schema:
///             type: object
///             properties:
///               entity:
///                 description: the seed entity to find related ones for
///                 type: string
///                 default: ""
///                 example: "tree"
///               page:
///                 $ref: '#/definitions/PageNumber'
///               pageSize:
///                 $ref: '#/definitions/PageSize'
///               filter:
///                 $ref: '#/definitions/Filter'
///               filterMode:
///                 $ref: '#/definitions/FilterMode'
///               blacklists:
///                 $ref: '#/definitions/Blacklists'
///               sortBy:
///                 description: criterion to use for retrieving the related entities
///                 type: string
///                 default: "proximity"
///                 example: "proximity"
///                 enum: ["proximity", "frequency", "spread"]
///               includeCount:
///                 $ref: '#/definitions/IncludeCount'
///               countOnly:
///                 $ref: '#/definitions/CountOnly'
///                 
///       responses:
///         200:
///           description: Successful response
///           schema: 
///             $ref: '#/definitions/EntityList'
/// </example>
ClassMethod GetRelatedEntitiesPOST(namespace As %String, pDomainId As %Integer) As %Status [ Internal ]
{
	quit ..GetRelatedEntities(namespace, pDomainId)
}

/// <example language="swagger">
///       summary: |
///         Retrieves entities related to a seed entity based on proximity or direct relationships
///       tags: ["Entities"]
///       parameters:
///         - $ref: '#/parameters/domainParam'
///         - name: entity
///           description: the seed entity to find related entities for
///           in: path
///           required: true
///           type: string
///         - name: RequestBody
///           description: JSON object with a list of query-specific arguments
///           in: body
///           schema:
///             type: object
///             properties:
///               entity:
///                 description: if set, overrides value of path parameter
///                 type: string
///                 default: ""
///                 example: ""
///               page:
///                 $ref: '#/definitions/PageNumber'
///               pageSize:
///                 $ref: '#/definitions/PageSize'
///               filter:
///                 $ref: '#/definitions/Filter'
///               filterMode:
///                 $ref: '#/definitions/FilterMode'
///               blacklists:
///                 $ref: '#/definitions/Blacklists'
///               sortBy:
///                 description: criterion to use for retrieving the related entities
///                 type: string
///                 default: "proximity"
///                 example: "proximity"
///                 enum: ["proximity", "frequency", "spread"]
///               includeCount:
///                 $ref: '#/definitions/IncludeCount'
///               countOnly:
///                 $ref: '#/definitions/CountOnly'
///                 
///       responses:
///         200:
///           description: Successful response
///           schema: 
///             $ref: '#/definitions/EntityList'
/// </example>
ClassMethod GetRelatedEntities(namespace As %String, pDomainId As %Integer, pEntity As %String = "") As %Status
{
	set tSC = $$$OK
	$$$IKRESTINITDEBUG
	try {
		do ..ResolveDomainId(.pDomainId)
		set:'%request.Content.%IsDefined("sortBy") %request.Content.sortBy = "proximity"
		
		set pEntity = ..ParseList("entity", pEntity)
		
		set tResult = { }
		
		set tSC = ..ParseArgs(pDomainId, .tPage, .tPageSize, .tFilter, .tFilterMode, .tBlackLists)
		quit:$$$ISERR(tSC)
		
		// BDB753
		if (%request.Content.includeCount || %request.Content.countOnly) {
			if (%request.Content.sortBy = "proximity") {
				
				// no GetCount method...
				set tSC = ##class(%iKnow.Semantics.ProximityAPI).GetProfile(.tEntities, pDomainId, $lg(pEntity), 0, 0, tFilter, tBlackLists)
				quit:$$$ISERR(tSC)
				set tCount=0, i=""
				for {
					set i = $order(tEntities(i))
					quit:i=""
					set tCount = tCount+1
				}

			} else {
				set:$g(tBlackLists)'="" tResult.warning = "Blacklists not reflected in count"
				set tCount = ##class(%iKnow.Queries.EntityAPI).GetRelatedCount(pDomainId, pEntity, tFilter,,, .tSC)
				quit:$$$ISERR(tSC)
			}
			set tResult.count = tCount
		}
		quit:%request.Content.countOnly
		
		set tResult.entities = []
		
		if (%request.Content.sortBy = "proximity") {
			
			// BDB728
			if $ll(pEntity)>1 {
				set tSC = $$$ERROR($$$GeneralError, "sortBy='proximity' only supports a single seed entity")
				quit
			}
			
			set tSC = ##class(%iKnow.Semantics.ProximityAPI).GetProfile(.tEntities, pDomainId, $lg(pEntity), tPage, tPageSize, tFilter, tBlackLists)
			quit:$$$ISERR(tSC)
		} else {
			set tSortMode = $case(%request.Content.sortBy, "frequency":$$$SORTBYFREQUENCY, "spread":$$$SORTBYSPREAD)
			set tSC = ##class(%iKnow.Queries.EntityAPI).GetRelated(.tEntities, pDomainId, pEntity, tPage, tPageSize, tFilter, tFilterMode,,,, tSortMode, tBlackLists)
			quit:$$$ISERR(tSC)
		}
		
		set i=""
		for {
			set i = $order(tEntities(i), 1, tEntData) 
			quit:i=""
			
			set tJSON = { "id":(+$lg(tEntData,1)), "value":($lg(tEntData,2)) }
			if (%request.Content.sortBy="proximity") {
				set tJSON.proximity = +$lg(tEntData,3)
			} else {
				set tJSON.frequency = +$lg(tEntData,3)
				set tJSON.spread = +$lg(tEntData,4)
			}
			do tResult.entities.%Push(tJSON)
		}
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit ..%ProcessResult(tSC, $g(tResult))
}

/// Simplified version of <method>GetEntityDetails</method> for HTTP GET requests
/// <example language="swagger">
///       summary: |
///         Retrieves details for the supplied entity
///       tags: ["Entities"]
///       parameters:
///         - $ref: '#/parameters/domainParam'
///         - name: entity
///           description: the entity whose details need to be returned
///           in: path
///           required: true
///           type: string
///                 
///       responses:
///         200:
///           description: Successful response
///           schema: 
///             title: EntityDetails
///             type: object
///             required:
///               - id
///               - value
///             properties:
///               id:
///                 type: integer
///                 description: unique entity ID
///               value:
///                 type: string
///                 description: entity value
///               metricsAsConcept:
///                 type: object
///                 properties:
///                   frequency:
///                     type: integer
///                     description: number of times the entity occurs in the result set
///                   spread:
///                     type: integer
///                     description: number of distinct sources the entity occurs in in the result set
///                   tfidf:
///                     type: number
///                     description: TFIDF-based metric expressing relevance of the entity in this result set
///               metricsAsRelation:
///                 type: object
///                 properties:
///                   frequency:
///                     type: integer
///                     description: number of times the entity occurs in the result set
///                   spread:
///                     type: integer
///                     description: number of distinct sources the entity occurs in in the result set
///                   tfidf:
///                     type: number
///                     description: TFIDF-based metric expressing relevance of the entity in this result set
///               metricsAsAny:
///                 type: object
///                 properties:
///                   frequency:
///                     type: integer
///                     description: number of times the entity occurs in the result set
///                   spread:
///                     type: integer
///                     description: number of distinct sources the entity occurs in in the result set
///                   tfidf:
///                     type: number
///                     description: TFIDF-based metric expressing relevance of the entity in this result set
/// </example>
ClassMethod GetEntityDetailsGET(namespace As %String, pDomainId As %Integer, pEntity As %String) As %Status [ Internal ]
{
	quit ..GetEntityDetails(namespace, pDomainId, pEntity)
}

/// Simplified version of <method>GetEntityDetails</method> for HTTP POST requests
/// <example language="swagger">
///       summary: |
///         Retrieves details for the supplied entity
///       tags: ["Entities"]
///       parameters:
///         - $ref: '#/parameters/domainParam'
///         - name: RequestBody
///           description: JSON object with a list of query-specific arguments
///           in: body
///           required: true
///           schema:
///             type: object
///             required: ["entity"]
///             properties:
///               entity:
///                 description: if set, overrides the value of the path parameter
///                 type: string
///                 default: ""
///               filter:
///                 description: if set, restricts the dataset on which metrics should be based
///                 $ref: '#/definitions/Filter'
///               useStems:
///                 description: only available when the domain has stemming enabled
///                 type: boolean
///                 default: 0
///                 format: integer
///               roles:
///                 description: roles for which the metrics need to be retrieved
///                 type: array
///                 default: ["concept", "relation", "any"]
///                 example: ["concept", "relation", "any"]
///                 items:
///                   type: string
///                   enum: ["concept", "relation", "any"]
///               includeMetrics:
///                 description: metrics to retrieve
///                 type: array
///                 default: ["frequency", "spread", "tfidf"]
///                 example: ["frequency", "spread", "tfidf"]
///                 items:
///                   type: string
///                   enum: ["frequency", "spread", "tfidf"]
///                 
///       responses:
///         200:
///           description: Successful response
///           schema: 
///             title: EntityDetails
///             type: object
///             required:
///               - id
///               - value
///             properties:
///               id:
///                 type: integer
///                 description: unique entity ID
///               value:
///                 type: string
///                 description: entity value
///               metricsAsConcept:
///                 type: object
///                 properties:
///                   frequency:
///                     type: integer
///                     description: number of times the entity occurs in the result set
///                   spread:
///                     type: integer
///                     description: number of distinct sources the entity occurs in in the result set
///                   tfidf:
///                     type: number
///                     description: TFIDF-based metric expressing relevance of the entity in this result set
///               metricsAsRelation:
///                 type: object
///                 properties:
///                   frequency:
///                     type: integer
///                     description: number of times the entity occurs in the result set
///                   spread:
///                     type: integer
///                     description: number of distinct sources the entity occurs in in the result set
///                   tfidf:
///                     type: number
///                     description: TFIDF-based metric expressing relevance of the entity in this result set
///               metricsAsAny:
///                 type: object
///                 properties:
///                   frequency:
///                     type: integer
///                     description: number of times the entity occurs in the result set
///                   spread:
///                     type: integer
///                     description: number of distinct sources the entity occurs in in the result set
///                   tfidf:
///                     type: number
///                     description: TFIDF-based metric expressing relevance of the entity in this result set
/// </example>
ClassMethod GetEntityDetailsPOST(namespace As %String, pDomainId As %Integer) As %Status [ Internal ]
{
	quit ..GetEntityDetails(namespace, pDomainId)
}

/// <example language="swagger">
///       summary: |
///         Retrieves details for the supplied entity
///       tags: ["Entities"]
///       parameters:
///         - $ref: '#/parameters/domainParam'
///         - name: entity
///           description: the entity whose details need to be returned
///           in: path
///           required: true
///           type: string
///         - name: RequestBody
///           description: JSON object with a list of query-specific arguments
///           in: body
///           schema:
///             type: object
///             properties:
///               entity:
///                 description: if set, overrides the value of the path parameter
///                 type: string
///                 default: ""
///               filter:
///                 description: if set, restricts the dataset on which metrics should be based
///                 $ref: '#/definitions/Filter'
///               useStems:
///                 description: only available when the domain has stemming enabled
///                 type: boolean
///                 default: 0
///                 format: integer
///               roles:
///                 description: roles for which the metrics need to be retrieved
///                 type: array
///                 default: ["concept", "relation", "any"]
///                 example: ["concept", "relation", "any"]
///                 items:
///                   type: string
///                   enum: ["concept", "relation", "any"]
///               includeMetrics:
///                 description: metrics to retrieve
///                 type: array
///                 default: ["frequency", "spread", "tfidf"]
///                 example: ["frequency", "spread", "tfidf"]
///                 items:
///                   type: string
///                   enum: ["frequency", "spread", "tfidf"]
///                 
///       responses:
///         200:
///           description: Successful response
///           schema: 
///             title: EntityDetails
///             type: object
///             required:
///               - id
///               - value
///             properties:
///               id:
///                 type: integer
///                 description: unique entity ID
///               value:
///                 type: string
///                 description: entity value
///               metricsAsConcept:
///                 type: object
///                 properties:
///                   frequency:
///                     type: integer
///                     description: number of times the entity occurs in the result set
///                   spread:
///                     type: integer
///                     description: number of distinct sources the entity occurs in in the result set
///                   tfidf:
///                     type: number
///                     description: TFIDF-based metric expressing relevance of the entity in this result set
///               metricsAsRelation:
///                 type: object
///                 properties:
///                   frequency:
///                     type: integer
///                     description: number of times the entity occurs in the result set
///                   spread:
///                     type: integer
///                     description: number of distinct sources the entity occurs in in the result set
///                   tfidf:
///                     type: number
///                     description: TFIDF-based metric expressing relevance of the entity in this result set
///               metricsAsAny:
///                 type: object
///                 properties:
///                   frequency:
///                     type: integer
///                     description: number of times the entity occurs in the result set
///                   spread:
///                     type: integer
///                     description: number of distinct sources the entity occurs in in the result set
///                   tfidf:
///                     type: number
///                     description: TFIDF-based metric expressing relevance of the entity in this result set
/// </example>
ClassMethod GetEntityDetails(namespace As %String, pDomainId As %Integer, pEntity As %String = "") As %Status
{
	set tSC = $$$OK
	$$$IKRESTINITDEBUG
	try {
		do ..ResolveDomainId(.pDomainId)
		set tUseStems = +%request.Content.useStems
		set:'%request.Content.%IsDefined("roles") %request.Content.roles = ["concept", "relation", "any"]
		
		set:%request.Content.%IsDefined("entity") pEntity = %request.Content.entity
		
		set tSC = ..ParseArgs(pDomainId,,, .tFilter)
		quit:$$$ISERR(tSC)
		
		set (tIncludeFrequency, tIncludeSpread, tIncludeDominance, tIncludeTFIDF) = 0
		if $isobject(%request.Content.includeMetrics) {
			set tIterator = %request.Content.includeMetrics.%GetIterator()
			while tIterator.%GetNext(,.tValue) {
				if (tValue="frequency") {
					set tIncludeFrequency = 1
				} elseif (tValue="spread") {
					set tIncludeSpread = 1
				} elseif (tValue="tfidf") {
					set tIncludeTFIDF = 1
				} elseif (tValue="dominance") {
					set tIncludeDominance = 1
				}
			}
		} else {
			set (tIncludeFrequency, tIncludeSpread, tIncludeDominance, tIncludeTFIDF) = 1
		}
		set:tIncludeTFIDF tDocCount = ##class(%iKnow.Queries.SourceAPI).GetCountByDomain(pDomainId, tFilter)
		
		set tID = $s(tUseStems:##class(%iKnow.Queries.EntityAPI).GetStemId(pDomainId, pEntity), 1:##class(%iKnow.Queries.EntityAPI).GetId(pDomainId, pEntity))
		set tResult = { "id": (tID), "value": (pEntity) }
		if (tID>0) {
			set tIterator = %request.Content.roles.%GetIterator()
			while tIterator.%GetNext(,.tRoleString) {
				set tRole = $case(tRoleString, "concept":$$$ENTTYPECONCEPT, "relation":$$$ENTTYPERELATION, "any":$$$ENTTYPEANY)
				set tJSON = { }
				
				set:tIncludeFrequency||tIncludeTFIDF tFreq = $s(tUseStems:##class(%iKnow.Queries.EntityAPI).GetStemFrequency(pDomainId, tID, tRole,, tFilter), 1:##class(%iKnow.Queries.EntityAPI).GetFrequency(pDomainId, tID, tRole,, tFilter))
				set:tIncludeFrequency tJSON.frequency = tFreq
				
				set:tIncludeSpread||tIncludeTFIDF tSpread = $s(tUseStems:##class(%iKnow.Queries.EntityAPI).GetStemSpread(pDomainId, tID, tRole, tFilter), 1:##class(%iKnow.Queries.EntityAPI).GetSpread(pDomainId, tID, tRole, tFilter))
				set:tIncludeSpread tJSON.spread = tSpread
				
				set:tIncludeTFIDF tJSON.tfidf = +$justify(tFreq * $zlog((tDocCount - tSpread + 0.5) / (tSpread + 0.5)),"",4)
							
				/* no support for filters yet!
				if tIncludeDominance && (tRole'=$$$ENTTYPEANY) {
					set tDomRole = $s(tUseStems:$case(tRole,$$$ENTTYPECONCEPT:$$$SDSTEMCONCEPT, $$$ENTTYPERELATION:$$$SDSTEMRELATION), 1:$case(tRole,$$$ENTTYPECONCEPT:$$$SDCONCEPT, $$$ENTTYPERELATION:$$$SDRELATION))
					set tJSON.dominance = ##class(%iKnow.Semantics.DominanceAPI).GetDomainValue(pDomainId, tID, tDomRole)
				}*/
				
				do tResult.%Set("metricsAs"_$zconvert(tRoleString,"w"), tJSON)
			}
		}
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit ..%ProcessResult(tSC, $g(tResult))
}

/// Simplified version of <method>GetCRCs</method> for HTTP GET requests
/// <example language="swagger">
///       summary: |
///         Retrieves the top CRCs for this domain
///       tags: ["Paths and CRCs"]
///       parameters:
///         - $ref: '#/parameters/domainParam'
///       responses:
///         200:
///           description: Successful response
///           schema: 
///             $ref: '#/definitions/CRCList'
/// </example>
ClassMethod GetCRCsGET(namespace As %String, pDomainId As %Integer) As %Status [ Internal ]
{
	quit ..GetCRCs(namespace, pDomainId)
}

/// <example language="swagger">
///       summary: |
///         Retrieves the top CRCs for this domain
///       tags: ["Paths and CRCs"]
///       parameters:
///         - $ref: '#/parameters/domainParam'
///         - name: RequestBody
///           description: JSON object with a list of query-specific arguments
///           in: body
///           schema:
///             type: object
///             properties:
///               page:
///                 $ref: '#/definitions/PageNumber'
///               pageSize:
///                 $ref: '#/definitions/PageSize'
///               filter:
///                 $ref: '#/definitions/Filter'
///               filterMode:
///                 $ref: '#/definitions/FilterMode'
///               sortBy:
///                 description: criterion to use for retrieving the top entities
///                 type: string
///                 default: "domainDefault"
///                 example: "domainDefault"
///                 enum: ["frequency", "spread", "domainDefault"]
///               includeCount:
///                 $ref: '#/definitions/IncludeCount'
///               countOnly:
///                 $ref: '#/definitions/CountOnly'
///                 
///       responses:
///         200:
///           description: Successful response
///           schema: 
///             $ref: '#/definitions/CRCList'
/// </example>
ClassMethod GetCRCs(namespace As %String, pDomainId As %Integer) As %Status
{
	set tSC = $$$OK
	$$$IKRESTINITDEBUG
	try {
		do ..ResolveDomainId(.pDomainId)
		set tSortBy = $s('%request.Content.%IsDefined("sortBy"):"domaindefault", 1:$$$LOWER(%request.Content.sortBy))

		set tResult = { }
		
		
		set tSC = ..ParseArgs(pDomainId, .tPage, .tPageSize, .tFilter, .tFilterMode)
		quit:$$$ISERR(tSC)
		
		// BDB753
		if (%request.Content.includeCount || %request.Content.countOnly) {
			set tCount = ##class(%iKnow.Queries.CrcAPI).GetCountByDomain(pDomainId, tFilter, .tSC)
			quit:$$$ISERR(tSC)
			set tResult.count = tCount
		}
		quit:%request.Content.countOnly
		
		set tResult.crcs = []
		
		if (tSortBy="domaindefault") || (tSortBy="frequency") || (tSortBy="spread") {
			
			set tSortMode = $case(tSortBy, "domaindefault":$$$SORTBYDOMAINDEFAULT, "frequency":$$$SORTBYFREQUENCY, "spread":$$$SORTBYSPREAD)
			set tSC = ##class(%iKnow.Queries.CrcAPI).GetTop(.tCRCs, pDomainId, tPage, tPageSize, tFilter, tFilterMode, tSortMode)
			quit:$$$ISERR(tSC)
			
		} else {
			set tSC = $$$ERROR($$$NotImplemented)
			quit
		}
		
		set i=""
		for {
			set i = $order(tCRCs(i), 1, tCRCData) 
			quit:i=""
			
			set tJSON = { "id":(+$lg(tCRCData,1)), "master":($lg(tCRCData,2)), "relation":($lg(tCRCData,3)), "slave":($lg(tCRCData,4)),
							"frequency": (+$lg(tCRCData,5)), "spread": (+$lg(tCRCData,6)) }
							
			do tResult.crcs.%Push(tJSON)
		}
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit ..%ProcessResult(tSC, $g(tResult))
}

/// Simplified version of <method>GetCRCsByEntity</method> for HTTP GET requests
/// <example language="swagger">
///       summary: |
///         Retrieves the CRCs containing a designated entity
///       tags: ["Paths and CRCs"]
///       parameters:
///         - $ref: '#/parameters/domainParam'
///         - name: entity
///           description: the entity to query for
///           in: path
///           required: true
///           type: string
///                 
///       responses:
///         200:
///           description: Successful response
///           schema:
///             $ref: '#/definitions/CRCList'
/// </example>
ClassMethod GetCRCsByEntityGET(namespace As %String, pDomainId As %Integer, pEntity As %String = "") As %Status [ Internal ]
{
	quit ..GetCRCsByEntity(namespace, pDomainId, pEntity)
}

/// Simplified version of <method>GetCRCsByEntity</method> for HTTP POST requests
/// <example language="swagger">
///       summary: |
///         Retrieves the CRCs containing a designated entity
///       tags: ["Paths and CRCs"]
///       parameters:
///         - $ref: '#/parameters/domainParam'
///         - name: RequestBody
///           description: JSON object with a list of query-specific arguments
///           in: body
///           required: true
///           schema:
///             type: object
///             required: ["entity"]
///             properties:
///               entity:
///                 description: seed entity or list of entities to query for
///                 type: array
///                 items:
///                   type: string
///                 default: ""
///                 example: "tree"
///               page:
///                 $ref: '#/definitions/PageNumber'
///               pageSize:
///                 $ref: '#/definitions/PageSize'
///               filter:
///                 $ref: '#/definitions/Filter'
///               filterMode:
///                 $ref: '#/definitions/FilterMode'
///               positions:
///                 description: CRC positions to query
///                 type: array
///                 default: ["master", "relation", "slave"]
///                 example: ["master", "relation", "slave"]
///                 items:
///                   type: string
///                   enum: ["master", "relation", "slave"]
///               actualFormOnly:
///                 type: boolean
///                 format: integer
///                 description: when this domain supports stemming, set to true to restrict to the supplied actual form only
///                 default: 0
///               includeCount:
///                 $ref: '#/definitions/IncludeCount'
///               countOnly:
///                 $ref: '#/definitions/CountOnly'
///                 
///       responses:
///         200:
///           description: Successful response
///           schema:
///             $ref: '#/definitions/CRCList'
/// </example>
ClassMethod GetCRCsByEntityPOST(namespace As %String, pDomainId As %Integer) As %Status [ Internal ]
{
	quit ..GetCRCsByEntity(namespace, pDomainId)
}

/// <example language="swagger">
///       summary: |
///         Retrieves the CRCs containing a designated entity
///       tags: ["Paths and CRCs"]
///       parameters:
///         - $ref: '#/parameters/domainParam'
///         - name: entity
///           description: the entity to query for
///           in: path
///           required: true
///           type: string
///         - name: RequestBody
///           description: JSON object with a list of query-specific arguments
///           in: body
///           schema:
///             type: object
///             properties:
///               entity:
///                 description: if set, takes precedence over the path parameter
///                 type: array
///                 items:
///                   type: string
///                 default: ""
///               page:
///                 $ref: '#/definitions/PageNumber'
///               pageSize:
///                 $ref: '#/definitions/PageSize'
///               filter:
///                 $ref: '#/definitions/Filter'
///               filterMode:
///                 $ref: '#/definitions/FilterMode'
///               positions:
///                 description: CRC positions to query
///                 type: array
///                 default: ["master", "relation", "slave"]
///                 example: ["master", "relation", "slave"]
///                 items:
///                   type: string
///                   enum: ["master", "relation", "slave"]
///               actualFormOnly:
///                 type: boolean
///                 format: integer
///                 description: when this domain supports stemming, set to true to restrict to the supplied actual form only
///                 default: 0
///               includeCount:
///                 $ref: '#/definitions/IncludeCount'
///               countOnly:
///                 $ref: '#/definitions/CountOnly'
///                 
///       responses:
///         200:
///           description: Successful response
///           schema:
///             $ref: '#/definitions/CRCList'
/// </example>
ClassMethod GetCRCsByEntity(namespace As %String, pDomainId As %Integer, pEntity As %String = "") As %Status
{
	set tSC = $$$OK
	$$$IKRESTINITDEBUG
	try {
		do ..ResolveDomainId(.pDomainId)
		
		set tResult = { }
		
		set pEntity = ..ParseList("entity", $g(pEntity))
		set tSC = ..ParseArgs(pDomainId, .tPage, .tPageSize, .tFilter, .tFilterMode)
		quit:$$$ISERR(tSC)
		
		if %request.Content.%IsDefined("positions") {
			set tPositions = 0, tIterator = %request.Content.positions.%GetIterator()
			while tIterator.%GetNext(,.tPos) {
				set tPositions = tPositions + $case(tPos,"master":$$$USEPOSM, "relation":$$$USEPOSR, "slave":$$$USEPOSS)
			}
		} else {
			set tPositions = $$$USEPOSALL
		}
		
		// BDB753
		if (%request.Content.includeCount || %request.Content.countOnly) {
			set tCount = ##class(%iKnow.Queries.CrcAPI).GetCountByEntities(pDomainId, pEntity, tFilter, tPositions, .tSC, %request.Content.actualFormOnly)
			quit:$$$ISERR(tSC)
			set tResult.count = tCount
		}
		quit:%request.Content.countOnly
		
		set tResult.crcs = []
		
		set tSC = ##class(%iKnow.Queries.CrcAPI).GetByEntities(.tCRCs, pDomainId, pEntity, tPage, tPageSize, tFilter, tFilterMode, tPositions, +%request.Content.actualFormOnly)
		quit:$$$ISERR(tSC)
		
		set i=""
		for {
			set i = $order(tCRCs(i), 1, tCRCData) 
			quit:i=""
			
			set tJSON = { "id":(+$lg(tCRCData,1)), "master":($lg(tCRCData,2)), "relation":($lg(tCRCData,3)), "slave":($lg(tCRCData,4)),
							"frequency": (+$lg(tCRCData,5)), "spread": (+$lg(tCRCData,6)) }
			do:$lg(tCRCData,2)="" tJSON.%Remove("master")
			do:$lg(tCRCData,4)="" tJSON.%Remove("slave")
							
			do tResult.crcs.%Push(tJSON)
		}
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit ..%ProcessResult(tSC, $g(tResult))
}

/// Simplified version of <method>GetPathsByEntity</method> for HTTP GET requests
/// <example language="swagger">
///       summary: |
///         Retrieves the paths containing a designated entity
///       tags: ["Paths and CRCs"]
///       parameters:
///         - $ref: '#/parameters/domainParam'
///         - name: entity
///           description: the entity to query for
///           in: path
///           required: true
///           type: string
///       responses:
///         200:
///           description: Successful response
///           schema:
///             title: PathList
///             type: object
///             properties:
///               paths:
///                 type: array
///                 items:
///                   title: Path
///                   properties:
///                     id:
///                       description: path ID
///                       type: integer
///                     entities:
///                       description: entities in this path
///                       type: array
///                       items:
///                         title: PathEntity
///                         type: object
///                         required:
///                           - id
///                           - entity
///                         properties:
///                           id:
///                             description: unique entity ID
///                             type: integer
///                           entity:
///                             description: entity value
///                             type: string
///                           partId:
///                             description: entity occurrence ID
///                             type: integer
///                           role:
///                             description: role of this entity in the path
///                             type: string
///                             enum: ["concept", "relation", "pathRelevant"]
///                           stemId:
///                             description: stem ID for this entity, if the domain is configured for stemming
///                             type: integer
///                           stem:
///                             description: stem value of this entity, if the domain is configured for stemming
///                             type: string
///                           attributes:
///                             description: semantic attributes for this entity
///                             type: array
///                             items:
///                               title: AttributeInfo
///                               type: object
///                               required: ["type", "level"]
///                               properties:
///                                 type:
///                                   description: name of the attribute
///                                   type: string
///                                 level:
///                                   description: level at which the attribute applies
///                                   type: string
///                                   enum: ["path", "word"] 
///                                 words:
///                                   description: if level="word", the actual words affected
///                                   type: string
///                                 properties:
///                                   description: attribute properties
///                                   type: object
/// </example>
ClassMethod GetPathsByEntityGET(namespace As %String, pDomainId As %Integer, pEntity As %String = "") As %Status [ Internal ]
{
	quit ..GetPathsByEntity(namespace, pDomainId, pEntity)
}

/// Simplified version of <method>GetPathsByEntity</method> for HTTP POST requests
/// <example language="swagger">
///       summary: |
///         Retrieves the paths containing a designated entity
///       tags: ["Paths and CRCs"]
///       parameters:
///         - $ref: '#/parameters/domainParam'
///         - name: RequestBody
///           description: JSON object with a list of query-specific arguments
///           in: body
///           required: true
///           schema:
///             type: object
///             required: ["entity"]
///             properties:
///               entity:
///                 description: seed entity or list of entities to query paths for
///                 type: array
///                 items:
///                   type: string
///                 default: ""
///                 example: "tree"
///               page:
///                 $ref: '#/definitions/PageNumber'
///               pageSize:
///                 $ref: '#/definitions/PageSize'
///               filter:
///                 $ref: '#/definitions/Filter'
///               includeDetails:
///                 description: whether or not to include details on the entities for each path
///                 type: boolean
///                 default: 1
///                 format: integer
///               actualFormOnly:
///                 type: boolean
///                 format: integer
///                 description: when this domain supports stemming, set to true to restrict to the supplied actual form only
///                 default: 0
///               setOperation:
///                 type: string
///                 enum: ["union", "intersect"]
///                 description: when supplying multiple entities, controls how the results for each entity should be combined
///               includeCount:
///                 $ref: '#/definitions/IncludeCount'
///               countOnly:
///                 $ref: '#/definitions/CountOnly'
///                 
///       responses:
///         200:
///           description: Successful response
///           schema:
///             title: PathList
///             type: object
///             properties:
///               paths:
///                 type: array
///                 items:
///                   title: Path
///                   properties:
///                     id:
///                       description: path ID
///                       type: integer
///                     entities:
///                       description: entities in this path
///                       type: array
///                       items:
///                         title: PathEntity
///                         type: object
///                         required:
///                           - id
///                           - entity
///                         properties:
///                           id:
///                             description: unique entity ID
///                             type: integer
///                           entity:
///                             description: entity value
///                             type: string
///                           partId:
///                             description: entity occurrence ID
///                             type: integer
///                           role:
///                             description: role of this entity in the path
///                             type: string
///                             enum: ["concept", "relation", "pathRelevant"]
///                           stemId:
///                             description: stem ID for this entity, if the domain is configured for stemming
///                             type: integer
///                           stem:
///                             description: stem value of this entity, if the domain is configured for stemming
///                             type: string
///                           attributes:
///                             description: semantic attributes for this entity
///                             type: array
///                             items:
///                               title: AttributeInfo
///                               type: object
///                               required: ["type", "level"]
///                               properties:
///                                 type:
///                                   description: name of the attribute
///                                   type: string
///                                 level:
///                                   description: level at which the attribute applies
///                                   type: string
///                                   enum: ["path", "word"] 
///                                 words:
///                                   description: if level="word", the actual words affected
///                                   type: string 
///                                 properties:
///                                   description: attribute properties
///                                   type: object
///               count:
///                 description: total number of paths, ignoring page and pageSize
///                 type: integer
/// </example>
ClassMethod GetPathsByEntityPOST(namespace As %String, pDomainId As %Integer) As %Status [ Internal ]
{
	quit ..GetPathsByEntity(namespace, pDomainId)
}

/// <example language="swagger">
///       summary: |
///         Retrieves the paths containing a designated entity
///       tags: ["Paths and CRCs"]
///       parameters:
///         - $ref: '#/parameters/domainParam'
///         - name: entity
///           description: the entity to query for
///           in: path
///           required: true
///           type: string
///         - name: RequestBody
///           description: JSON object with a list of query-specific arguments
///           in: body
///           schema:
///             type: object
///             properties:
///               entity:
///                 description: if set, takes precedence over the path parameter
///                 type: array
///                 items:
///                   type: string
///                 default: ""
///               page:
///                 $ref: '#/definitions/PageNumber'
///               pageSize:
///                 $ref: '#/definitions/PageSize'
///               filter:
///                 $ref: '#/definitions/Filter'
///               includeDetails:
///                 description: whether or not to include details on the entities for each path
///                 type: boolean
///                 default: 1
///                 format: integer
///               actualFormOnly:
///                 type: boolean
///                 format: integer
///                 description: when this domain supports stemming, set to true to restrict to the supplied actual form only
///                 default: 0
///               setOperation:
///                 type: string
///                 enum: ["union", "intersect"]
///                 description: when supplying multiple entities, controls how the results for each entity should be combined
///               includeCount:
///                 $ref: '#/definitions/IncludeCount'
///               countOnly:
///                 $ref: '#/definitions/CountOnly'
///                 
///       responses:
///         200:
///           description: Successful response
///           schema:
///             title: PathList
///             type: object
///             properties:
///               paths:
///                 type: array
///                 items:
///                   title: Path
///                   properties:
///                     id:
///                       description: path ID
///                       type: integer
///                     entities:
///                       description: entities in this path
///                       type: array
///                       items:
///                         title: PathEntity
///                         type: object
///                         required:
///                           - id
///                           - entity
///                         properties:
///                           id:
///                             description: unique entity ID
///                             type: integer
///                           entity:
///                             description: entity value
///                             type: string
///                           partId:
///                             description: entity occurrence ID
///                             type: integer
///                           role:
///                             description: role of this entity in the path
///                             type: string
///                             enum: ["concept", "relation", "pathRelevant"]
///                           stemId:
///                             description: stem ID for this entity, if the domain is configured for stemming
///                             type: integer
///                           stem:
///                             description: stem value of this entity, if the domain is configured for stemming
///                             type: string
///                           attributes:
///                             description: semantic attributes for this entity
///                             type: array
///                             items:
///                               title: AttributeInfo
///                               type: object
///                               required: ["type", "level"]
///                               properties:
///                                 type:
///                                   description: name of the attribute
///                                   type: string
///                                 level:
///                                   description: level at which the attribute applies
///                                   type: string
///                                   enum: ["path", "word"] 
///                                 words:
///                                   description: if level="word", the actual words affected
///                                   type: string
///                                 properties:
///                                   description: attribute properties
///                                   type: object
///               count:
///                 description: total number of paths, ignoring page and pageSize
///                 type: integer
/// </example>
ClassMethod GetPathsByEntity(namespace As %String, pDomainId As %Integer, pEntity As %String = "") As %Status
{
	set tSC = $$$OK
	$$$IKRESTINITDEBUG
	try {
		do ..ResolveDomainId(.pDomainId)
		set:'%request.Content.%IsDefined("includeDetails") %request.Content.includeDetails = 1
		set tSetOp = $s($$$LOWER(%request.Content.setOperation)="intersect":$$$INTERSECT, 1:$$$UNION)
		
		set tResult = { }
		
		set pEntity = ..ParseList("entity", $g(pEntity))
		set tSC = ..ParseArgs(pDomainId, .tPage, .tPageSize, .tFilter, .tFilterMode)
		quit:$$$ISERR(tSC)
		
		// BDB753
		if (%request.Content.includeCount || %request.Content.countOnly) {
			set tCount = ##class(%iKnow.Queries.PathAPI).GetCountByEntities(pDomainId, pEntity, tFilter, tSetOp, .tSC, %request.Content.actualFormOnly)
			quit:$$$ISERR(tSC)
			set tResult.count = tCount
		}
		quit:%request.Content.countOnly
		
		set tResult.paths = []
		
		set tSC = ##class(%iKnow.Queries.PathAPI).GetByEntities(.tPaths, pDomainId, pEntity, tPage, tPageSize, tFilter, tSetOp, +%request.Content.actualFormOnly)
		quit:$$$ISERR(tSC)
		
		set i=""
		for {
			set i = $order(tPaths(i), 1, tPathData) 
			quit:i=""
			
			set tJSON = { "id":(+$lg(tPathData,1)), "entities": [] }
			
			if %request.Content.includeDetails {
				$$$IKRESTSTARTTIMER(details)
				
				set tSC = ##class(%iKnow.Queries.PathAPI).GetEntities(.tEntities, pDomainId, tJSON.id)
				quit:$$$ISERR(tSC)
				set j=""
				for {
					set j = $order(tEntities(j), 1, tEntData)
					quit:j=""

					set tEnt = { "id":(+$lg(tEntData,3)), "partId":(+$lg(tEntData,2)), "entity":($lg(tEntData,4)),
								 "role":($case($lg(tEntData,6),$$$ENTTYPECONCEPT:"concept",$$$ENTTYPERELATION:"relation",$$$ENTTYPENONREL:"nonRelevant",$$$ENTTYPEPATHREL:"pathRelevant")) }
					set:$lg(tEntData,7) tEnt.stemId = +$lg(tEntData,7), tEnt.stem = $lg(tEntData,8)
					
					do tJSON.entities.%Push(tEnt)
					
					set tSC = ##class(%iKnow.Queries.EntityAPI).GetOccurrenceAttributes(.tAttributes, pDomainId, tEnt.partId)
					quit:$$$ISERR(tSC)
					if $d(tAttributes) {
						set k="", tEnt.attributes = []
						for {
							set k = $order(tAttributes(k),1,tAttData)
							quit:k=""
							set tAtt = { "type": ($lg(tAttData,2)), "level":($case($lg(tAttData,3), $$$IKATTLVLPATH:"path", $$$IKATTLVLSENT:"word")) }
							if +$lg(tAttData,4) {
								set tAtt.words = "", tWordBits = $lg(tAttData,4)
								for l = 1:1:$l(tWordBits) {
									set:$e(tWordBits,l) tAtt.words = $s(tAtt.words="":"", 1:tAtt.words_" ")_$p(tEnt.entity," ",l)
								}
							}
							
							// BDB845
							if $d(tAttributes(k))>1 {
								set tAtt.properties = {}, tPropName=""
								for {
									set tPropName = $order(tAttributes(k,tPropName),1,tPropValue)
									quit:tPropName=""
									do tAtt.properties.%Set(tPropName, tPropValue)
								}
							}
							
							do tEnt.attributes.%Push(tAtt)
						}
					}
					
					set tJSON.sourceId = ##class(%iKnow.Queries.PathAPI).GetSourceId(pDomainId, tJSON.id)
					set tJSON.sentenceId = ##class(%iKnow.Queries.PathAPI).GetSentenceId(pDomainId, tJSON.id)
				}
				quit:$$$ISERR(tSC)
				$$$IKRESTSTOPTIMER(details)
			} else {
				set ptr=0, tEntities=$lg(tPathData,2)
				while $listnext(tEntities,ptr,tEntId) {
					do tJSON.entities.%Push({"id": (tEntId), "entity": (##class(%iKnow.Queries.EntityAPI).GetValueInternal(pDomainId, tEntId)) })
				}
			}
							
			do tResult.paths.%Push(tJSON)
		}
		quit:$$$ISERR(tSC)
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit ..%ProcessResult(tSC, $g(tResult))
}

/// Simplified version of <method>GetSentenceDetails</method> for HTTP GET requests
/// <example language="swagger">
///       summary: |
///         Retrieves the details for a particular sentence
///       tags: ["Sentences"]
///       parameters:
///         - $ref: '#/parameters/domainParam'
///         - name: id
///           description: the sentence ID to query for
///           in: path
///           required: true
///           type: integer
/// 
///       responses:
///         200:
///           description: Successful response
///           schema:
///             $ref: '#/definitions/SentenceDetails'
/// </example>
ClassMethod GetSentenceDetailsGET(namespace As %String, pDomainId As %Integer, pSentenceId As %Integer) As %Status [ Internal ]
{
	quit ..GetSentenceDetails(namespace, pDomainId, pSentenceId)
}

/// <example language="swagger">
///       summary: |
///         Retrieves the details for a particular sentence
///       tags: ["Sentences"]
///       parameters:
///         - $ref: '#/parameters/domainParam'
///         - name: id
///           description: the sentence ID to query for
///           in: path
///           required: true
///           type: integer
///         - name: RequestBody
///           description: JSON object with a list of query-specific arguments
///           in: body
///           schema:
///             type: object
///             properties:
///               highlight:
///                 $ref: '#/definitions/Highlighting'
///               virtualSourceId:
///                 description: if set, the sentence will be looked up in the context of this virtual source
///                 type: integer
/// 
///       responses:
///         200:
///           description: Successful response
///           schema:
///             $ref: '#/definitions/SentenceDetails'
/// </example>
ClassMethod GetSentenceDetails(namespace As %String, pDomainId As %Integer, pSentenceId As %Integer) As %Status
{
	set tSC = $$$OK
	$$$IKRESTINITDEBUG
	try {
		do ..ResolveDomainId(.pDomainId)
		set vSrcId = +%request.Content.virtualSourceId
		do ..ParseHighlight(.tHighlight)
		
		set tResult = { "id": (pSentenceId), "parts" : [] }
		set tResult.text = $s($d(tHighlight):##class(%iKnow.Queries.SentenceAPI).GetHighlighted(pDomainId, pSentenceId, .tHighlight, vSrcId,, .tSC), 1:##class(%iKnow.Queries.SentenceAPI).GetValue(pDomainId, pSentenceId,, vSrcId))
		
		set tSC = ##class(%iKnow.Queries.SentenceAPI).GetParts(.tParts, pDomainId, pSentenceId,,, vSrcId)
		quit:$$$ISERR(tSC)
		
		set j=""
		for {
			set j = $order(tParts(j), 1, tPartData)
			quit:j=""
			
			set tPart = { "partId":(+$lg(tPartData,1)), "literal":($lg(tPartData,3)),
						 "role":($case($lg(tPartData,4),$$$ENTTYPECONCEPT:"concept",$$$ENTTYPERELATION:"relation",$$$ENTTYPENONREL:"nonRelevant",$$$ENTTYPEPATHREL:"pathRelevant")) }
			set:$ld(tPartData,2,tEntId)&&tEntId tPart.entityId = +tEntId, tPart.entity = ##class(%iKnow.Queries.EntityAPI).GetValueInternal(pDomainId, tEntId, vSrcId, 0)
			set:$ld(tPartData,5,tStemId)&&tStemId tPart.stemId = +tStemId, tPart.stem = ##class(%iKnow.Queries.EntityAPI).GetValueInternal(pDomainId, tStemId, vSrcId, 1)
			
			do tResult.parts.%Push(tPart)
			
			set tSC = ##class(%iKnow.Queries.EntityAPI).GetOccurrenceAttributes(.tAttributes, pDomainId, tPart.partId, vSrcId)
			quit:$$$ISERR(tSC)
			if $d(tAttributes) {
				set k="", tPart.attributes = []
				for {
					set k = $order(tAttributes(k),1,tAttData)
					quit:k=""
					set tAtt = { "type": ($lg(tAttData,2)), "level":($case($lg(tAttData,3), $$$IKATTLVLPATH:"path", $$$IKATTLVLSENT:"word")) }
					if +$lg(tAttData,4) {
						set tAtt.words = "", tWordBits = $lg(tAttData,4)
						for l = 1:1:$l(tWordBits) {
							set:$e(tWordBits,l) tAtt.words = $s(tAtt.words="":"", 1:tAtt.words_" ")_$p(tPart.entity," ",l)
						}
					}
					
					// BDB845
					if $d(tAttributes(k))>1 {
						set tAtt.properties = {}, tPropName=""
						for {
							set tPropName = $order(tAttributes(k,tPropName),1,tPropValue)
							quit:tPropName=""
							do tAtt.properties.%Set(tPropName, tPropValue)
						}
					}
					
					do tPart.attributes.%Push(tAtt)
				}
			}
		}
		
		set tResult.sourceId = ##class(%iKnow.Queries.SentenceAPI).GetSourceId(pDomainId, pSentenceId)
		
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit ..%ProcessResult(tSC, $g(tResult))
}

/// Simplified version of <method>GetSentencesbyEntity</method> for HTTP GET requests
/// <example language="swagger">
///       summary: |
///         Retrieves the sentences containing a given entity
///       tags: ["Sentences"]
///       parameters:
///         - $ref: '#/parameters/domainParam'
///         - name: entity
///           description: the entity to query for
///           in: path
///           required: true
///           type: string
/// 
///       responses:
///         200:
///           description: Successful response
///           schema:
///             title: SentenceList
///             type: object
///             required: ["sentences"]
///             properties:
///               sentences:
///                 type: array
///                 items:
///                   $ref: '#/definitions/SentenceDetails'
/// </example>
ClassMethod GetSentencesByEntityGET(namespace As %String, pDomainId As %Integer, pEntity As %String = "") As %Status [ Internal ]
{
	quit ..GetSentencesByEntity(namespace, pDomainId, pEntity)
}

/// Simplified version of <method>GetSentencesbyEntity</method> for HTTP POST requests
/// <example language="swagger">
///       summary: |
///         Retrieves the sentences containing a given entity
///       tags: ["Sentences"]
///       parameters:
///         - $ref: '#/parameters/domainParam'
///         - name: RequestBody
///           description: JSON object with a list of query-specific arguments
///           in: body
///           required: true
///           schema:
///             type: object
///             required: ["entity"]
///             properties:
///               entity:
///                 description: if set, takes precedence over the corresponding path parameter
///                 type: array
///                 items:
///                   type: string
///                 default: ""
///                 example: "palm tree"
///               page:
///                 $ref: '#/definitions/PageNumber'
///               pageSize:
///                 $ref: '#/definitions/PageSize'
///               filter:
///                 $ref: '#/definitions/Filter'
///               highlight:
///                 $ref: '#/definitions/Highlighting'
///               includeDetails:
///                 description: whether or not to include details on the entities for each sentence
///                 type: boolean
///                 default: 1
///                 format: integer
///               actualFormOnly:
///                 type: boolean
///                 format: integer
///                 description: when this domain supports stemming, set to true to restrict to the supplied actual form only
///                 default: 0
///               setOperation:
///                 type: string
///                 enum: ["union", "intersect"]
///                 description: when supplying multiple entities, controls how the results for each entity should be combined
///               includeCount:
///                 $ref: '#/definitions/IncludeCount'
///               countOnly:
///                 $ref: '#/definitions/CountOnly'
/// 
///       responses:
///         200:
///           description: Successful response
///           schema:
///             title: SentenceList
///             type: object
///             required: ["sentences"]
///             properties:
///               sentences:
///                 type: array
///                 items:
///                   $ref: '#/definitions/SentenceDetails'
///               count:
///                 description: total number of paths, ignoring page and pageSize (if RequestBody.includeCount is set)
///                 type: integer
/// </example>
ClassMethod GetSentencesByEntityPOST(namespace As %String, pDomainId As %Integer) As %Status [ Internal ]
{
	quit ..GetSentencesByEntity(namespace, pDomainId)
}

/// <example language="swagger">
///       summary: |
///         Retrieves the sentences containing a given entity
///       tags: ["Sentences"]
///       parameters:
///         - $ref: '#/parameters/domainParam'
///         - name: entity
///           description: the entity to query for
///           in: path
///           required: true
///           type: string
///         - name: RequestBody
///           description: JSON object with a list of query-specific arguments
///           in: body
///           schema:
///             type: object
///             properties:
///               entity:
///                 description: if set, takes precedence over the corresponding path parameter
///                 type: array
///                 items:
///                   type: string
///                 default: ""
///               page:
///                 $ref: '#/definitions/PageNumber'
///               pageSize:
///                 $ref: '#/definitions/PageSize'
///               filter:
///                 $ref: '#/definitions/Filter'
///               highlight:
///                 $ref: '#/definitions/Highlighting'
///               includeDetails:
///                 description: whether or not to include details on the entities for each sentence
///                 type: boolean
///                 default: 1
///                 format: integer
///               actualFormOnly:
///                 type: boolean
///                 format: integer
///                 description: when this domain supports stemming, set to true to restrict to the supplied actual form only
///                 default: 0
///               setOperation:
///                 type: string
///                 enum: ["union", "intersect"]
///                 description: when supplying multiple entities, controls how the results for each entity should be combined
///               includeCount:
///                 $ref: '#/definitions/IncludeCount'
///               countOnly:
///                 $ref: '#/definitions/CountOnly'
/// 
///       responses:
///         200:
///           description: Successful response
///           schema:
///             title: SentenceList
///             type: object
///             required: ["sentences"]
///             properties:
///               sentences:
///                 type: array
///                 items:
///                   $ref: '#/definitions/SentenceDetails'
///               count:
///                 description: total number of paths, ignoring page and pageSize (if RequestBody.includeCount is set)
///                 type: integer
/// </example>
ClassMethod GetSentencesByEntity(namespace As %String, pDomainId As %Integer, pEntity As %String = "") As %Status
{
	set tSC = $$$OK
	$$$IKRESTINITDEBUG
	try {
		do ..ResolveDomainId(.pDomainId)
		do ..ParseHighlight(.tHighlight)
		set pEntity = ..ParseList("entity", $g(pEntity))
		set tSC = ..ParseArgs(pDomainId, .tPage, .tPageSize, .tFilter)
		quit:$$$ISERR(tSC)
		
		set:'%request.Content.%IsDefined("includeDetails") %request.Content.includeDetails = 1
		set tSetOp = $s($$$LOWER(%request.Content.setOperation)="intersect":$$$INTERSECT, 1:$$$UNION)
		
		set tResult = {}
		
		// BDB753
		if (%request.Content.includeCount || %request.Content.countOnly) {
			set tCount = ##class(%iKnow.Queries.SentenceAPI).GetCountByEntities(pDomainId, pEntity, tFilter, tSetOp, .tSC, %request.Content.actualFormOnly)
			quit:$$$ISERR(tSC)
			set tResult.count = tCount
		}
		quit:%request.Content.countOnly
		
		set tResult.sentences = []
		set tSC = ##class(%iKnow.Queries.SentenceAPI).GetByEntities(.tSentences, pDomainId, pEntity, tFilter, tPage, tPageSize, tSetOp, +%request.Content.actualFormOnly)
		quit:$$$ISERR(tSC)
		
		set i = ""
		for {
			set i = $order(tSentences(i), 1, tSentenceData)
			quit:i=""
			
			set tSentObj = { "id": (+$lg(tSentenceData,3)), "sourceId": (+$lg(tSentenceData,1)) }
			set tSentObj.text = $s($d(tHighlight):##class(%iKnow.Queries.SentenceAPI).GetHighlighted(pDomainId, tSentObj.id, .tHighlight,,, .tSC), 1:$lg(tSentenceData,4))
			
			if (%request.Content.includeDetails) {
				set tSentObj.parts = []
				set tSC = ##class(%iKnow.Queries.SentenceAPI).GetParts(.tParts, pDomainId, tSentObj.id)
				quit:$$$ISERR(tSC)
				set j=""
				for {
					set j = $order(tParts(j), 1, tPartData)
					quit:j=""
					
					set tPart = { "partId":(+$lg(tPartData,1)), "literal":($lg(tPartData,3)),
								 "role":($case($lg(tPartData,4),$$$ENTTYPECONCEPT:"concept",$$$ENTTYPERELATION:"relation",$$$ENTTYPENONREL:"nonRelevant",$$$ENTTYPEPATHREL:"pathRelevant")) }
					set:$ld(tPartData,2,tEntId)&&tEntId tPart.entityId = +tEntId, tPart.entity = ##class(%iKnow.Queries.EntityAPI).GetValueInternal(pDomainId, tEntId,, 0)
					set:$ld(tPartData,5,tStemId)&&tStemId tPart.stemId = +tStemId, tPart.stem = ##class(%iKnow.Queries.EntityAPI).GetValueInternal(pDomainId, tStemId,, 1)
					
					do tSentObj.parts.%Push(tPart)
					
					set tSC = ##class(%iKnow.Queries.EntityAPI).GetOccurrenceAttributes(.tAttributes, pDomainId, tPart.partId)
					quit:$$$ISERR(tSC)
					if $d(tAttributes) {
						set k="", tPart.attributes = []
						for {
							set k = $order(tAttributes(k),1,tAttData)
							quit:k=""
							set tAtt = { "type": ($lg(tAttData,2)), "level":($case($lg(tAttData,3), $$$IKATTLVLPATH:"path", $$$IKATTLVLSENT:"word")) }
							if +$lg(tAttData,4) {
								set tAtt.words = "", tWordBits = $lg(tAttData,4)
								for l = 1:1:$l(tWordBits) {
									set:$e(tWordBits,l) tAtt.words = $s(tAtt.words="":"", 1:tAtt.words_" ")_$p(tPart.entity," ",l)
								}
							}
							
							// BDB845
							if $d(tAttributes(k))>1 {
								set tAtt.properties = {}, tPropName=""
								for {
									set tPropName = $order(tAttributes(k,tPropName),1,tPropValue)
									quit:tPropName=""
									do tAtt.properties.%Set(tPropName, tPropValue)
								}
							}
							
							do tPart.attributes.%Push(tAtt)
						}
					}
				}
			}
			
			do tResult.sentences.%Push(tSentObj)
		}
		
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit ..%ProcessResult(tSC, $g(tResult))
}

/// <example language="swagger">
///       summary: |
///         Adds a source to the domain
///       tags: ["Sources"]
///       parameters:
///         - $ref: '#/parameters/domainParam'
///         - name: RequestBody
///           description: JSON object with a list of query-specific arguments
///           in: body
///           schema:
///             type: object
///             required: ["reference", "text"]
///             properties:
///               reference:
///                 description: a string to be used for building the new record's external ID
///                 type: string
///               text:
///                 description: the text to index
///                 type: string
///               configuration:
///                 description: name of a valid configuration object to use or the two-letter ISO code for the language to use (if no such configuration exists)
///                 type: string
///                 example: en
///               virtual:
///                 description: if true, the source will be added as a virtual one
///                 type: boolean
///                 default: 0
///                 format: integer
///               metadata:
///                 description: map of metadata field values to set for the document
///                 type: object
/// 
///       responses:
///         200:
///           description: Successful response
///           schema:
///             type: object
///             required: ["id"]
///             properties:
///               id:
///                 description: source ID of the newly created record
///                 type: integer
/// </example>
ClassMethod AddSource(namespace As %String, pDomainId As %Integer) As %Status
{
	set tSC = $$$OK
	$$$IKRESTINITDEBUG
	try {
		do ..ResolveDomainId(.pDomainId)
		set tConfig = %request.Content.configuration
		if (tConfig'="") {
			set tConfigObj = ##class(%iKnow.Configuration).NameIndexOpen(tConfig)
			if $isobject(tConfigObj) {
				// OK
			} elseif $l(tConfig)=2 {
				set tConfigObj = ##class(%iKnow.Configuration).%New("cfg"_$random(9999999),0,$lb(tConfig))
				set tSC = tConfigObj.%Save()
				quit:$$$ISERR(tSC)
				set tConfig = tConfigObj.Name, tDropConfig = 1
			} else {
				set tSC = $$$ERROR($$$IKConfigurationNotFound, tConfig)
				quit
			}
		} else {
			set tConfig = $$$DEFAULTCONFIG
		}
		
		set tDomainName = $system.iKnow.GetDomainName(pDomainId)
		
		set tResult = {} 
		set tSC = $system.iKnow.IndexString(tDomainName, %request.Content.reference, %request.Content.text, tConfig, +%request.Content.virtual, .tSrcId)
		quit:$$$ISERR(tSC)
		
		set tResult = { "id": (tSrcId) }
		
		
		if %request.Content.%IsDefined("metadata") && '%request.Content.virtual {
			$$$IKRESTSTARTTIMER(metadata)
			
			set tSC = ##class(%iKnow.Queries.MetadataAPI).GetFields(.tFields, pDomainId)
			quit:$$$ISERR(tSC)
			set i=""
			for {
				set i = $order(tFields(i),1,tFieldData)
				quit:i=""
				set tFieldName = $lg(tFieldData,2)
				set tFieldInfo(tFieldName) = $lg(tFieldData,4)
				set tFieldInfo(tFieldName,"id") = $lg(tFieldData,1)
			}
			kill tFields
			
			set tIterator = %request.Content.metadata.%GetIterator()
			while tIterator.%GetNext(.tKey, .tValue) {
				continue:'$d(tFieldInfo(tKey,"id"),tFieldId)
				if $g(tFieldInfo(tKey))=$$$MDDTDATE {
					set tValue = $zdth(tValue)
				}
				set tSC = ##class(%iKnow.Queries.MetadataAPI).SetValueByIdInternal(pDomainId,tFieldId,tSrcId,tValue,1)
				quit:$$$ISERR(tSC)
			}
			$$$IKRESTSTOPTIMER(metadata)
		}
		
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	if $$$ISERR(tSC) && $g(tSrcId) && ((tDomainName'="") || 'pDomainId) {
		if %request.Content.virtual {
			do $system.iKnow.DeleteVirtualSource(tDomainName, tSrcId)
		} else {
			do $system.iKnow.DeleteSource(tDomainName, tSrcId)
		}
	}
	if $g(tDropConfig) {
		do ##class(%iKnow.Configuration).NameIndexDelete(tConfig)
	}
	quit ..%ProcessResult(tSC, $g(tResult))
}

/// <example language="swagger">
///       summary: |
///         Highlights the supplied text
///       tags: ["Miscellaneous"]
///       parameters:
///         - name: RequestBody
///           description: JSON object with a list of query-specific arguments
///           in: body
///           schema:
///             type: object
///             required: ["highlight", "text"]
///             properties:
///               text:
///                 description: the text to highlight
///                 example: "This text is in urgent need of fancy markup!"
///                 type: string
///               configuration:
///                 description: name of a valid configuration object to use or the two-letter ISO code for the language to use (if no such configuration exists)
///                 type: string
///                 example: en
///               highlight:
///                 description: highlighting specification
///                 $ref: '#/definitions/Highlighting'
///                 example: [ { role: "concept", style: "[]" }, { role: "relation", style: "{}" }]
/// 
///       responses:
///         200:
///           description: Successful response
///           schema:
///             type: object
///             required: ["text"]
///             properties:
///               text:
///                 description: the highlighted text
///                 type: string
/// </example>
ClassMethod HighlightSYS(namespace As %String) As %Status
{
	quit ..Highlight(namespace, 0)
}

/// <example language="swagger">
///       summary: |
///         Highlights the supplied text
///       tags: ["Miscellaneous"]
///       parameters:
///         - $ref: '#/parameters/domainParam'
///         - name: RequestBody
///           description: JSON object with a list of query-specific arguments
///           in: body
///           schema:
///             type: object
///             required: ["highlight", "text"]
///             properties:
///               text:
///                 description: the text to highlight
///                 example: "This text is in urgent need of fancy markup!"
///                 type: string
///               configuration:
///                 description: name of a valid configuration object to use or the two-letter ISO code for the language to use (if no such configuration exists)
///                 type: string
///                 example: en
///               highlight:
///                 description: highlighting specification
///                 $ref: '#/definitions/Highlighting'
///                 example: [ { role: "concept", style: "[]" }, { role: "relation", style: "{}" }]
/// 
///       responses:
///         200:
///           description: Successful response
///           schema:
///             type: object
///             required: ["text"]
///             properties:
///               text:
///                 description: the highlighted text
///                 type: string
/// </example>
ClassMethod Highlight(namespace As %String, pDomainId As %Integer = 0) As %Status
{
	set tSC = $$$OK
	$$$IKRESTINITDEBUG
	try {
				
		if (pDomainId'=0) {
			do ..ResolveDomainId(.pDomainId)
		}
		
		set tConfig = %request.Content.configuration
		if (tConfig'="") {
			set tConfigObj = ##class(%iKnow.Configuration).NameIndexOpen(tConfig)
			if $isobject(tConfigObj) {
				// OK
			} elseif $l(tConfig)=2 {
				set tConfigObj = ##class(%iKnow.Configuration).%New("cfg"_$random(9999999),0,$lb(tConfig))
				if (tConfigObj="") { set tSC = $g(%objlasterror,$$$ERROR($$$GeneralError,"Failed to initialize configuration")) quit }
				set tSC = tConfigObj.%Save()
				quit:$$$ISERR(tSC)
				set tConfig = tConfigObj.Name, tDropConfig = 1
			} else {
				set tSC = $$$ERROR($$$IKConfigurationNotFound, tConfig)
				quit
			}
		} else {
			set tConfig = $$$GETPARAM(pDomainId,$$$IKPDEFAULTCONFIG,$$$DEFAULTCONFIG)
		}
		
		set tSC = ..ParseHighlight(.tHighlight)
		quit:$$$ISERR(tSC)
		
		set tResult = {} 
		set tResult.text = $system.iKnow.Highlight(%request.Content.text, .tHighlight, tConfig,, .tSC)
		quit:$$$ISERR(tSC)
		
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	if $g(tDropConfig) {
		do ##class(%iKnow.Configuration).NameIndexDelete(tConfig)
	}
	quit ..%ProcessResult(tSC, $g(tResult))
}

/// <example language="swagger">
///       summary: |
///         Indexes the supplied text and returns concepts, relations and CRCs
///       tags: ["Miscellaneous"]
///       parameters:
///         - name: RequestBody
///           description: JSON object with a list of query-specific arguments
///           in: body
///           schema:
///             type: object
///             required: ["highlight", "text"]
///             properties:
///               text:
///                 description: the text to index
///                 example: "This text is in urgent need of fancy markup!"
///                 type: string
///               configuration:
///                 description: name of a valid configuration object to use or the two-letter ISO code for the language to use (if no such configuration exists)
///                 type: string
///                 example: en
///               summarize:
///                 description: if set to a nonzero value, the text returned will be a summary of the full contents, measuring this many sentences
///                 type: number
///                 default: 0
///               highlight:
///                 description: highlighting specification
///                 $ref: '#/definitions/Highlighting'
///                 example: [ { role: "concept", style: "[]" }, { role: "relation", style: "{}" }]
///               includeMatches:
///                 description: whether or not to retrieve dictionary matches for the indexed record
///                 type: boolean
///                 format: integer
///                 default: 0
///               dictionaries:
///                 description: if set, limits results to these dictionary IDs
///                 default: []
///                 type: array
///                 items:
///                   type: integer
///               includeDictionaryDetails:
///                 description: whether or not to retrieve dictionary details as well
///                 type: boolean
///                 format: integer
///                 default: 1
///               includeMatchDetails:
///                 description: whether or not to entity-level match details as well
///                 type: boolean
///                 format: integer
///                 default: 0
/// 
///       responses:
///         200:
///           description: Successful response
///           schema:
///             type: object
///             required: ["text"]
///             properties:
///               text:
///                 description: the highlighted text
///                 type: string
///               concepts:
///                 description: list of concepts for this text
///                 type: array
///                 items:
///                   type: object
///                   properties:
///                     value:
///                       type: string
///                     frequency:
///                       type: integer
///                     dominance:
///                       type: integer
///               relations:
///                 description: list of relations for this text
///                 type: array
///                 items:
///                   type: object
///                   properties:
///                     value:
///                       type: string
///                     frequency:
///                       type: integer
///                     dominance:
///                       type: integer
///               matches:
///                 description: list of dictionary matches for this text
///                 type: array
///                 items:
///                   $ref: '#/definitions/MatchListItem'
/// </example>
ClassMethod IndexSYS(namespace As %String) As %Status [ Internal ]
{
	quit ..Index(namespace, 0)
}

/// <example language="swagger">
///       summary: |
///         Indexes the supplied text and returns concepts, relations and CRCs
///       tags: ["Miscellaneous"]
///       parameters:
///         - $ref: '#/parameters/domainParam'
///         - name: RequestBody
///           description: JSON object with a list of query-specific arguments
///           in: body
///           schema:
///             type: object
///             required: ["highlight", "text"]
///             properties:
///               text:
///                 description: the text to index
///                 example: "This text is in urgent need of fancy markup!"
///                 type: string
///               configuration:
///                 description: name of a valid configuration object to use or the two-letter ISO code for the language to use (if no such configuration exists)
///                 type: string
///                 example: en
///               summarize:
///                 description: if set to a nonzero value, the text returned will be a summary of the full contents, measuring this many sentences
///                 type: number
///                 default: 0
///               highlight:
///                 description: highlighting specification
///                 $ref: '#/definitions/Highlighting'
///                 example: [ { role: "concept", style: "[]" }, { role: "relation", style: "{}" }]
///               includeMatches:
///                 description: whether or not to retrieve dictionary matches for the indexed record
///                 type: boolean
///                 format: integer
///                 default: 0
///               dictionaries:
///                 description: if set, limits results to these dictionary IDs
///                 default: []
///                 type: array
///                 items:
///                   type: integer
///               includeDictionaryDetails:
///                 description: whether or not to retrieve dictionary details as well
///                 type: boolean
///                 format: integer
///                 default: 1
///               includeMatchDetails:
///                 description: whether or not to entity-level match details as well
///                 type: boolean
///                 format: integer
///                 default: 0
/// 
///       responses:
///         200:
///           description: Successful response
///           schema:
///             type: object
///             required: ["text"]
///             properties:
///               text:
///                 description: the highlighted text
///                 type: string
///               concepts:
///                 description: list of concepts for this text
///                 type: array
///                 items:
///                   type: object
///                   properties:
///                     value:
///                       type: string
///                     frequency:
///                       type: integer
///                     dominance:
///                       type: integer
///               relations:
///                 description: list of relations for this text
///                 type: array
///                 items:
///                   type: object
///                   properties:
///                     value:
///                       type: string
///                     frequency:
///                       type: integer
///                     dominance:
///                       type: integer
///               matches:
///                 description: list of dictionary matches for this text
///                 type: array
///                 items:
///                   $ref: '#/definitions/MatchListItem'
/// </example>
ClassMethod Index(namespace As %String, pDomainId As %Integer = 0) As %Status
{
	set tSC = $$$OK
	$$$IKRESTINITDEBUG
	try {
				
		if (pDomainId=0) {
			set tDomainName = ""
		} else {
			do ..ResolveDomainId(.pDomainId)
			set tDomainName = $system.iKnow.GetDomainName(pDomainId)
		}
		
		// resolve configuration
		set tConfig = %request.Content.configuration
		if (tConfig'="") {
			set tConfigObj = ##class(%iKnow.Configuration).NameIndexOpen(tConfig)
			if $isobject(tConfigObj) {
				// OK
			} elseif $l(tConfig)=2 {
				set tConfigObj = ##class(%iKnow.Configuration).%New("cfg"_$random(9999999),0,$lb(tConfig))
				set tSC = tConfigObj.%Save()
				quit:$$$ISERR(tSC)
				set tConfig = tConfigObj.Name, tDropConfig = 1
			} else {
				set tSC = $$$ERROR($$$IKConfigurationNotFound, tConfig)
				quit
			}
		}
		
		// index record
		set tSC = $system.iKnow.IndexString(tDomainName, 123, %request.Content.text, tConfig, 1, .tSrcId)
		quit:$$$ISERR(tSC)
		
		
		// retrieve indexing results
		set tResult = { "concepts": [], "relations": [], "crcs": [] }
		
		$$$IKRESTSTARTTIMER(entities)
		set tSC = ##class(%iKnow.Queries.EntityAPI).GetBySource(.tEntities, pDomainId, tSrcId, 0, 0, $$$ENTTYPECONCEPT)
		quit:$$$ISERR(tSC)
		set i = ""
		for {
			set i = $order(tEntities(i), 1, tData)
			quit:i=""
			do tResult.concepts.%Push({ 
				"value": ($lg(tData,2)), 
				"frequency": ($lg(tData,3)),
				"dominance": (##class(%iKnow.Semantics.DominanceAPI).GetSourceValue(pDomainId, tSrcId, $lg(tData,1), $$$SDCONCEPT))
			})
		}
		set tSC = ##class(%iKnow.Queries.EntityAPI).GetBySource(.tEntities, pDomainId, tSrcId, 0, 0, $$$ENTTYPERELATION)
		quit:$$$ISERR(tSC)
		set i = ""
		for {
			set i = $order(tEntities(i), 1, tData)
			quit:i=""
			do tResult.relations.%Push({ 
				"value": ($lg(tData,2)), 
				"frequency": ($lg(tData,3)),
				"dominance": (##class(%iKnow.Semantics.DominanceAPI).GetSourceValue(pDomainId, tSrcId, $lg(tData,1), $$$SDRELATION))
			})
		}
		$$$IKRESTSTOPTIMER(entities)
		
		$$$IKRESTSTARTTIMER(crcs)
		set tSC = ##class(%iKnow.Queries.CrcAPI).GetBySource(.tCRCs, pDomainId, tSrcId, 0, 0)
		quit:$$$ISERR(tSC)
		set i = ""
		for {
			set i = $order(tCRCs(i), 1, tData)
			quit:i=""
			do tResult.crcs.%Push({ 
				"master": ($lg(tData,2)), 
				"relation": ($lg(tData,3)), 
				"slave": ($lg(tData,4)), 
				"frequency": ($lg(tData,5))
			})
		}
		$$$IKRESTSTOPTIMER(crcs)
		
		// now highlight text
		$$$IKRESTSTARTTIMER(text)
		set tSummarize = +%request.Content.summarize
		if 'tSummarize {
			set tSC = ##class(%iKnow.Queries.SentenceAPI).GetBySource(.tSentences, pDomainId, tSrcId, 0, 0)
			quit:$$$ISERR(tSC)
		} else {
			set tSC = ##class(%iKnow.Queries.SourceAPI).GetSummary(.tSentences, pDomainId, tSrcId, tSummarize)
			quit:$$$ISERR(tSC)
		}
		
		set tSC = ..ParseHighlight(.tHighlight)
		quit:$$$ISERR(tSC)
		
		set i="", tText="", tPrevSentId=0
		for {
			set i = $order(tSentences(i),1,tSentData) 
			quit:i=""
			
			set tSentId = $lg(tSentData,1)
			set:tText'="" tText = tText_" "
			set:tPrevSentId&&(tSentId>(tPrevSentId+1)) tText = tText_"... "
			
			set tText = tText _ $s($d(tHighlight):##class(%iKnow.Queries.SentenceAPI).GetHighlighted(pDomainId, tSentId, .tHighlight, tSrcId,, .tSC), 1:$lg(tSentData,2))
			
			set tPrevSentId = tSentId
		}
		set tResult.text = tText
		$$$IKRESTSTOPTIMER(text)
		
		// retrieve matches
		if (%request.Content.includeMatches) {
			set tIncludeDictDetails = $s(%request.Content.%IsDefined("includeDictionaryDetails"):%request.Content.includeDictionaryDetails, 1:1)
			set tIncludeMatchDetails = $s(%request.Content.%IsDefined("includeMatchDetails"):%request.Content.includeMatchDetails, 1:0)
			
			set tDictionaries = ..ParseList("dictionaries")
			
			$$$IKRESTSTARTTIMER(matching)
			set tSC = ##class(%iKnow.Matching.MatchingAPI).MatchSource(pDomainId, tSrcId, tDictionaries)
			quit:$$$ISERR(tSC)
			$$$IKRESTSTOPTIMER(matching)
			
			$$$IKRESTSTARTTIMER(getmatches)
			set tResult.matches = []
			set tSC = ##class(%iKnow.Matching.MatchingAPI).GetMatchesBySourceId(.tMatches, pDomainId, tSrcId, tDictionaries, 0, 0)
			quit:$$$ISERR(tSC)
			set i = ""
			for {
				set i = $order(tMatches(i), 1, tMatchData)
				quit:i=""
				
				set tJSON = { "id": (+$lg(tMatchData,1)), "score": (+$normalize($lg(tMatchData,8),4)), "partialCount": (+$lg(tMatchData,11)), "ordered":(+$lg(tMatchData,14)), "negatedCount": (+$lg(tMatchData,15)) }
				
				set tJSON.term = { "id": (+$lg(tMatchData,5)) }
				
				// BDB734
				set tCrossDomainDict = (tJSON.term.id < 0)
				set tDictDomainId = $s(tCrossDomainDict:0, 1:pDomainId)
				
				if (tIncludeDictDetails) {
					set tTermObj = ##class(%iKnow.Objects.DictionaryTerm).PKINDEXOpen(tDictDomainId, $zabs($lg(tMatchData,5)))
					if (tTermObj.String["[") && (tTermObj.String[".") {
						set tSC = ##class(%iKnow.Matching.DictionaryAPI).GetTermElements(.tElems, tDictDomainId, tTermObj.DictionaryTermId)
						quit:$$$ISERR(tSC)
						set tSC = ##class(%iKnow.Matching.DictionaryAPI).GetFormatDetails(tDictDomainId, $lg(tElems(1),3), .tClass, .tParams)
						quit:$$$ISERR(tSC)
						set tJSON.term.formatClass = tClass
						set tJSON.term.formatParams = [], ptr=0
						while $listnext(tParams,ptr,tParam) { do tJSON.term.formatParams.%Push(tParam) }
					} else {
						set tJSON.term.string = tTermObj.String
					}
					set tJSON.term.item = { "id": (+$lg(tMatchData,3)), "uri": ($lg(tMatchData,4)), "name": (tTermObj.DictionaryItem.Name) }
					set tJSON.term.item.dictionary = { "id": (+$lg(tMatchData,2)), "name": (tTermObj.Dictionary.Name) }
				} else {
					set tJSON.term.item = { "id": (+$lg(tMatchData,3)), "uri": ($lg(tMatchData,4)) }
					set tJSON.term.item.dictionary = { "id": (+$lg(tMatchData,2)) }
				}
				
				set tJSON.sentenceId = ##class(%iKnow.Matching.MatchingAPI).GetSentenceIdForMatchTarget(pDomainId, $lg(tMatchData,6), $lg(tMatchData,7), $zabs(tSrcId))
				set tJSON.target = { "id": (+$lg(tMatchData,7)) }
				set tJSON.target.type = $case($lg(tMatchData,6), $$$DMTARGETENTITY:"entity", $$$DMTARGETCRC:"crc", $$$DMTARGETPATH:"path", $$$DMTARGETSENT:"sentence")
				
				do tResult.matches.%Push(tJSON)
				
				if (tIncludeMatchDetails) {
					$$$IKRESTSTARTTIMER(matchdetails)
					set tSC = ##class(%iKnow.Matching.MatchingAPI).GetMatchElements(.tElems, pDomainId, tJSON.id, $zabs(tSrcId))
					quit:$$$ISERR(tSC)
					set j="", tJSON.elements=[]
					for {
						set j = $order(tElems(j), 1, tElemData)
						quit:j=""
						set tJSONE = { "partId": (+$lg(tElemData,2)), "literal": ($lg(tElemData,4)), "score": (+$normalize($lg(tElemData,6),4)), "matchedWords": ($lg(tElemData,9)), "negated":(+$lg(tElemData,12)) }
						set:$lg(tElemData,3) tJSONE.entityId = +$lg(tElemData,3), tJSONE.entity = ##class(%iKnow.Queries.EntityAPI).GetValueInternal(pDomainId, tJSONE.entityId, $zabs(tSrcId))
						set:$lg(tElemData,11)'="" tJSONE.output = $lg(tElemData,11)
						set tJSONE.role = $case($lg(tElemData,5),$$$ENTTYPECONCEPT:"concept",$$$ENTTYPERELATION:"relation",$$$ENTTYPENONREL:"nonRelevant",$$$ENTTYPEPATHREL:"pathRelevant")
						do tJSON.elements.%Push(tJSONE)
					}
					$$$IKRESTSTOPTIMER(matchdetails)
				}	
			}
			$$$IKRESTSTOPTIMER(getmatches)
		}
		
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	if $g(tDropConfig) {
		do ##class(%iKnow.Configuration).NameIndexDelete(tConfig)
	}
	if $g(tSrcId) {
		do $system.iKnow.DeleteVirtualSource($g(tDomainName),tSrcId)
	}
	quit ..%ProcessResult(tSC, $g(tResult))
}

/// Simplified version of <method>DropSource</method> for HTTP GET requests.
/// <example language="swagger">
///       summary: |
///         Deletes a source from the domain
///       tags: ["Sources"]
///       parameters:
///         - $ref: '#/parameters/domainParam'
///         - name: source
///           description: the source ID to drop
///           in: path
///           required: true
///           type: integer
/// 
///       responses:
///         200:
///           description: Successful response
///           schema:
///             type: object
///             required:
///               - deleted
///             properties:
///               deleted:
///                 type: boolean
///                 format: integer
/// </example>
ClassMethod DropSourceGET(namespace As %String, pDomainId As %Integer, pSourceId As %Integer) As %Status [ Internal ]
{
	quit ..DropSource(namespace, pDomainId, pSourceId)
}

/// <example language="swagger">
///       summary: |
///         Deletes a source from the domain
///       tags: ["Sources"]
///       parameters:
///         - $ref: '#/parameters/domainParam'
///         - name: source
///           description: the source ID to drop
///           in: path
///           required: true
///           type: integer
///         - name: RequestBody
///           description: JSON object with a list of query-specific arguments
///           in: body
///           schema:
///             type: object
///             properties:
///               virtual:
///                 description: if set, the supplied source ID will be used to look up a virtual source
///                 type: boolean
///                 format: integer
///                 default: 0
/// 
///       responses:
///         200:
///           description: Successful response
///           schema:
///             type: object
///             required:
///               - deleted
///             properties:
///               deleted:
///                 type: boolean
///                 format: integer
/// </example>
ClassMethod DropSource(namespace As %String, pDomainId As %Integer, pSourceId As %Integer) As %Status
{
	set tSC = $$$OK
	$$$IKRESTINITDEBUG
	try {
		do ..ResolveDomainId(.pDomainId)
		set:%request.Content.virtual pSourceId = -$zabs(pSourceId)
		
		set tDomainName = $system.iKnow.GetDomainName(pDomainId)
		
		if (%request.Content.virtual) || (pSourceId<0) {
			set tSC = $system.iKnow.DeleteVirtualSource(tDomainName, pSourceId)
		} else {
			set tSC = $system.iKnow.DeleteSource(tDomainName, pSourceId)
		}
		set tResult = { "deleted": ($$$ISOK(tSC)) }
		
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	
	quit ..%ProcessResult(tSC, $g(tResult))
}

/// <example language="swagger">
///       summary: |
///         Registers metadata values for a given source
///       tags: ["Sources"]
///       parameters:
///         - $ref: '#/parameters/domainParam'
///         - name: source
///           description: the source ID whose metadata needs updating
///           in: path
///           required: true
///           type: integer
///         - name: RequestBody
///           description: JSON object with a list of query-specific arguments
///           in: body
///           schema:
///             type: object
///             properties:
///               metadata:
///                 description: map of metadata field values to set for this source
///                 type: object
/// 
///       responses:
///         200:
///           description: Successful response
///           schema:
///             type: object
///             required:
///               - updated
///             properties:
///               updated:
///                 type: boolean
///                 format: integer
/// </example>
ClassMethod SetMetadata(namespace As %String, pDomainId As %Integer, pSourceId As %Integer) As %Status
{
	set tSC = $$$OK
	$$$IKRESTINITDEBUG
	try {
		do ..ResolveDomainId(.pDomainId)
		
		set tSC = ##class(%iKnow.Queries.MetadataAPI).GetFields(.tFields, pDomainId)
		quit:$$$ISERR(tSC)
		set i=""
		for {
			set i = $order(tFields(i),1,tFieldData)
			quit:i=""
			set tFieldName = $lg(tFieldData,2)
			set tFieldInfo(tFieldName) = $lg(tFieldData,4)
			set tFieldInfo(tFieldName,"id") = $lg(tFieldData,1)
		}
		kill tFields
		
		set tIterator = %request.Content.metadata.%GetIterator()
		while tIterator.%GetNext(.tKey, .tValue) {
			continue:'$d(tFieldInfo(tKey,"id"),tFieldId)
			if $g(tFieldInfo(tKey))=$$$MDDTDATE {
				set tValue = $zdth(tValue)
			}
			set tSC = ##class(%iKnow.Queries.MetadataAPI).SetValueByIdInternal(pDomainId,tFieldId,pSourceId,tValue,1)
			quit:$$$ISERR(tSC)
		}
		quit:$$$ISERR(tSC)
		
		set tResult = { "updated": ($$$ISOK(tSC)) }
		
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit ..%ProcessResult(tSC, $g(tResult))
}

/// Simplified version of <method>GetBlacklists</method> for HTTP GET requests
/// <example language="swagger">
///       summary: |
///         Retrieves a list of available blacklists
///       tags: ["Blacklists"]
///       parameters:
///         - $ref: '#/parameters/domainParam'
/// 
///       responses:
///         200:
///           description: Successful response
///           schema:
///             $ref: '#/definitions/BlacklistList'
/// </example>
ClassMethod GetBlacklistsGET(namespace As %String, pDomainId As %Integer) As %Status [ Internal ]
{
	quit ..GetBlacklists(namespace, pDomainId)
}

/// <example language="swagger">
///       summary: |
///         Retrieves a list of available blacklists
///       tags: ["Blacklists"]
///       parameters:
///         - $ref: '#/parameters/domainParam'
///         - name: RequestBody
///           description: JSON object with a list of query-specific arguments
///           in: body
///           schema:
///             type: object
///             properties:
///               includeDetails:
///                 description: whether or not to retrieve blacklists' contents as well
///                 type: boolean
///                 format: integer
///               includeCrossDomain: 
///                 description: whether or not to include cross-domain blacklists
///                 type: boolean
///                 format: integer
/// 
///       responses:
///         200:
///           description: Successful response
///           schema:
///             $ref: '#/definitions/BlacklistList'
/// </example>
ClassMethod GetBlacklists(namespace As %String, pDomainId As %Integer) As %Status
{
	set tSC = $$$OK
	$$$IKRESTINITDEBUG
	try {
		do ..ResolveDomainId(.pDomainId)
		set:'%request.Content.%IsDefined("includeDetails") %request.Content.includeDetails = 1
		
		set tResult = { "blacklists": [] }
		
		set tSC = ##class(%iKnow.Utils.MaintenanceAPI).GetBlackLists(.tLists, pDomainId, +%request.Content.includeCrossDomain)
		quit:$$$ISERR(tSC)
		set i=""
		for {
			set i = $order(tLists(i),1,tListData)
			quit:i=""
			
			set tList = { "id":(+$lg(tListData,1)), "name":($lg(tListData,2)) }
			set:$ld(tListData,3,tDesc)&&(tDesc'="") tList.description = tDesc
			
			if %request.Content.includeDetails {
				set tList.elements = []
				set tSC = ##class(%iKnow.Utils.MaintenanceAPI).GetBlackListElements(.tElems, pDomainId, tList.id)
				quit:$$$ISERR(tSC)
				set j=""
				for {
					set j = $order(tElems(j),1,tElemData)
					quit:j=""
					do tList.elements.%Push($lg(tElemData,2))
				}
			}
			
			do tResult.blacklists.%Push(tList)
		}
		
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit ..%ProcessResult(tSC, $g(tResult))
}

/// <example language="swagger">
///       summary: |
///         Retrieves a particular blacklist's contents
///       tags: ["Blacklists"]
///       parameters:
///         - $ref: '#/parameters/domainParam'
///         - name: id
///           in: path
///           type: integer
///           description: ID of the blacklist being queried
///           required: true
/// 
///       responses:
///         200:
///           description: Successful response
///           schema:
///             $ref: '#/definitions/BlacklistDetails'
/// </example>
ClassMethod GetBlacklistDetails(namespace As %String, pDomainId As %Integer, pBlacklistId As %Integer) As %Status
{
	set tSC = $$$OK
	$$$IKRESTINITDEBUG
	try {
		do ..ResolveDomainId(.pDomainId)
		
		set tBL = ##class(%iKnow.Objects.BlackList).PKINDEXOpen(pDomainId, pBlacklistId)
		if '$isobject(tBL) {
			set tSC = $$$ERROR($$$IKSkipListDoesNotExist, pBlacklistId)
			quit
		}
		
		set tResult = { "id": (pBlacklistId), "name": (tBL.Name), "elements": [] }
		set:tBL.Description'="" tResult.description = tBL.Description

		set tSC = ##class(%iKnow.Utils.MaintenanceAPI).GetBlackListElements(.tElems, pDomainId, pBlacklistId)
		quit:$$$ISERR(tSC)
		set j=""
		for {
			set j = $order(tElems(j),1,tElemData)
			quit:j=""
			do tResult.elements.%Push($lg(tElemData,2))
		}
		
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit ..%ProcessResult(tSC, $g(tResult))
}

/// Simplified version of <method>CreateBlacklist</method> for HTTP GET requests
/// <example language="swagger">
///       summary: |
///         Creates a new blacklist
///       tags: ["Blacklists"]
///       parameters:
///         - $ref: '#/parameters/domainParam'
///         - name: name
///           in: path
///           description: name of the new blacklist
///           required: true
///           type: string
///       responses:
///         200:
///           description: Successful response
///           schema:
///             $ref: '#/definitions/BlacklistDetails'
/// </example>
ClassMethod CreateBlacklistGET(namespace As %String, pDomainId As %Integer, pName As %String = "") As %Status [ Internal ]
{
	quit ..CreateBlacklist(namespace, pDomainId, pName)
}

/// Simplified version of <method>CreateBlacklist</method> for HTTP POST requests
/// <example language="swagger">
///       summary: |
///         Creates a new blacklist
///       tags: ["Blacklists"]
///       parameters:
///         - $ref: '#/parameters/domainParam'
///         - name: RequestBody
///           description: JSON object with a list of query-specific arguments
///           in: body
///           required: true
///           schema:
///             type: object
///             required: ["name"]
///             properties:
///               name:
///                 description: name for the new blacklist
///                 type: string
///               description:
///                 type: string
///               elements: 
///                 type: array
///                 example: []
///                 items:
///                   type: string
/// 
///       responses:
///         200:
///           description: Successful response
///           schema:
///             $ref: '#/definitions/BlacklistDetails'
/// </example>
ClassMethod CreateBlacklistPOST(namespace As %String, pDomainId As %Integer) As %Status [ Internal ]
{
	quit ..CreateBlacklist(namespace, pDomainId)
}

/// <example language="swagger">
///       summary: |
///         Creates a new blacklist
///       tags: ["Blacklists"]
///       parameters:
///         - $ref: '#/parameters/domainParam'
///         - name: name
///           in: path
///           description: name of the new blacklist
///           required: true
///           type: string
///         - name: RequestBody
///           description: JSON object with a list of query-specific arguments
///           in: body
///           schema:
///             type: object
///             properties:
///               name:
///                 description: overrides what's passed in through the path parameter if set
///                 type: string
///               description:
///                 type: string
///               elements: 
///                 type: array
///                 example: []
///                 items:
///                   type: string
/// 
///       responses:
///         200:
///           description: Successful response
///           schema:
///             $ref: '#/definitions/BlacklistDetails'
/// </example>
ClassMethod CreateBlacklist(namespace As %String, pDomainId As %Integer, pName As %String = "") As %Status
{
	set tSC = $$$OK
	$$$IKRESTINITDEBUG
	try {
		do ..ResolveDomainId(.pDomainId)
		set:%request.Content.%IsDefined("name") pName = %request.Content.name
		
		set tID = ##class(%iKnow.Utils.MaintenanceAPI).CreateBlackList(pDomainId, pName, %request.Content.description, .tSC)
		quit:$$$ISERR(tSC)
		
		if %request.Content.%IsDefined("elements") {
			set tIterator = %request.Content.elements.%GetIterator()
			while tIterator.%GetNext(,.tEntry) {
				do ##class(%iKnow.Utils.MaintenanceAPI).AddStringToBlackList(pDomainId, tID, tEntry)
			}
		}

		set tResult = { "id": (tID), "name": (pName) }
		set:%request.Content.description'="" tResult.description = %request.Content.description
		set:%request.Content.%IsDefined("elements") tResult.elements = %request.Content.elements
		
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit ..%ProcessResult(tSC, $g(tResult))
}

/// <example language="swagger">
///       summary: |
///         Clears all entries for a given blacklist
///       tags: ["Blacklists"]
///       parameters:
///         - $ref: '#/parameters/domainParam'
///         - name: id
///           in: path
///           type: string
///           description: ID of the blacklist to clear
///           required: true
/// 
///       responses:
///         200:
///           description: Successful response
///           schema:
///             type: object
///             properties:
///               cleared:
///                 type: boolean
///                 format: integer
/// </example>
ClassMethod ClearBlacklist(namespace As %String, pDomainId As %Integer, pBlacklistId As %Integer) As %Status
{
	set tSC = $$$OK
	$$$IKRESTINITDEBUG
	try {
		do ..ResolveDomainId(.pDomainId)
		
		set tSC = ##class(%iKnow.Utils.MaintenanceAPI).ClearBlackList(pDomainId, pBlacklistId)

		set tResult = { "cleared": ($$$ISOK(tSC)) }
		
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit ..%ProcessResult(tSC, $g(tResult))
}

/// <example language="swagger">
///       summary: |
///         Drops a given blacklist
///       tags: ["Blacklists"]
///       parameters:
///         - $ref: '#/parameters/domainParam'
///         - name: id
///           in: path
///           type: string
///           description: ID of the blacklist to drop
///           required: true
/// 
///       responses:
///         200:
///           description: Successful response
///           schema:
///             type: object
///             properties:
///               dropped:
///                 type: boolean
///                 format: integer
/// </example>
ClassMethod DropBlacklist(namespace As %String, pDomainId As %Integer, pBlacklistId As %Integer) As %Status
{
	set tSC = $$$OK
	$$$IKRESTINITDEBUG
	try {
		do ..ResolveDomainId(.pDomainId)
		
		set tSC = ##class(%iKnow.Utils.MaintenanceAPI).DropBlackList(pDomainId, pBlacklistId)

		set tResult = { "dropped": ($$$ISOK(tSC)) }
		
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit ..%ProcessResult(tSC, $g(tResult))
}

/// Simplified version of <method>AddStringToBlacklist</method> for HTTP GET requests
/// <example language="swagger">
///       summary: |
///         Adds new elements to a given blacklist
///       tags: ["Blacklists"]
///       parameters:
///         - $ref: '#/parameters/domainParam'
///         - name: id
///           in: path
///           type: string
///           description: ID of the blacklist to extend
///           required: true
///         - name: string
///           in: path
///           type: string
///           description: element to add to the blacklist
///           required: true
/// 
///       responses:
///         200:
///           description: Successful response
///           schema:
///             type: object
///             properties:
///               added:
///                 description: number of elements added
///                 type: integer
/// </example>
ClassMethod AddStringToBlacklistGET(namespace As %String, pDomainId As %Integer, pBlacklistId As %Integer, pElements As %String = "") As %Status [ Internal ]
{
	quit ..AddStringToBlacklist(namespace, pDomainId, pBlacklistId, pElements)
}

/// Simplified version of <method>AddStringToBlacklist</method> for HTTP POST requests.
/// <example language="swagger">
///       summary: |
///         Adds new elements to a given blacklist
///       tags: ["Blacklists"]
///       parameters:
///         - $ref: '#/parameters/domainParam'
///         - name: id
///           in: path
///           type: string
///           description: ID of the blacklist to extend
///           required: true
///         - name: RequestBody
///           description: JSON object with a list of query-specific arguments
///           in: body
///           required: true
///           schema:
///             type: object
///             required: ["elements"]
///             properties:
///               elements: 
///                 description: array of entries to add to the blacklist
///                 type: array
///                 example: []
///                 items:
///                   type: string
/// 
///       responses:
///         200:
///           description: Successful response
///           schema:
///             type: object
///             properties:
///               added:
///                 description: number of elements added
///                 type: integer
/// </example>
ClassMethod AddStringToBlacklistPOST(namespace As %String, pDomainId As %Integer, pBlacklistId As %Integer) As %Status [ Internal ]
{
	quit ..AddStringToBlacklist(namespace, pDomainId, pBlacklistId)
}

/// <example language="swagger">
///       summary: |
///         Adds new elements to a given blacklist
///       tags: ["Blacklists"]
///       parameters:
///         - $ref: '#/parameters/domainParam'
///         - name: id
///           in: path
///           type: string
///           description: ID of the blacklist to extend
///           required: true
///         - name: string
///           in: path
///           type: string
///           description: element to add to the blacklist
///           required: true
///         - name: RequestBody
///           description: JSON object with a list of query-specific arguments
///           in: body
///           schema:
///             type: object
///             properties:
///               elements: 
///                 description: if set, overrides what's passed in through the path parameter
///                 type: array
///                 example: []
///                 items:
///                   type: string
/// 
///       responses:
///         200:
///           description: Successful response
///           schema:
///             type: object
///             properties:
///               added:
///                 description: number of elements added
///                 type: integer
/// </example>
ClassMethod AddStringToBlacklist(namespace As %String, pDomainId As %Integer, pBlacklistId As %Integer, pElements As %String = "") As %Status
{
	set tSC = $$$OK
	$$$IKRESTINITDEBUG
	try {
		do ..ResolveDomainId(.pDomainId)
		
		set tResult = { "added": 0 }
		
		set tIterator = ..ParseStringArray("elements", $g(pElements)).%GetIterator()
		while tIterator.%GetNext(,.tElem) {
			set tSC = ##class(%iKnow.Utils.MaintenanceAPI).AddStringToBlackList(pDomainId, pBlacklistId, tElem)
			set tResult.added = tResult.added + $$$ISOK(tSC)
		}
		
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit ..%ProcessResult(tSC, $g(tResult))
}

/// Simplified version of <method>RemoveStringFromBlacklist</method> for HTTP GET requests
/// <example language="swagger">
///       summary: |
///         Removes elements from a given blacklist
///       tags: ["Blacklists"]
///       parameters:
///         - $ref: '#/parameters/domainParam'
///         - name: id
///           in: path
///           type: string
///           description: ID of the blacklist to modify
///           required: true
///         - name: string
///           in: path
///           type: string
///           description: element to remove from the blacklist
///           required: true
/// 
///       responses:
///         200:
///           description: Successful response
///           schema:
///             type: object
///             properties:
///               removed:
///                 description: number of elements removed
///                 type: integer
/// </example>
ClassMethod RemoveStringFromBlacklistGET(namespace As %String, pDomainId As %Integer, pBlacklistId As %Integer, pElements As %String = "") As %Status [ Internal ]
{
	quit ..RemoveStringFromBlacklist(namespace, pDomainId, pBlacklistId, pElements)
}

/// Simplified version of <method>RemoveStringFromBlacklist</method> for HTTP POST requests
/// <example language="swagger">
///       summary: |
///         Removes elements from a given blacklist
///       tags: ["Blacklists"]
///       parameters:
///         - $ref: '#/parameters/domainParam'
///         - name: id
///           in: path
///           type: string
///           description: ID of the blacklist to modify
///           required: true
///         - name: RequestBody
///           description: JSON object with a list of query-specific arguments
///           in: body
///           required: true
///           schema:
///             type: object
///             required: ["elements"]
///             properties:
///               elements: 
///                 description: element or list of elements to remove from the blacklist
///                 type: array
///                 example: ["palm tree"]
///                 items:
///                   type: string
/// 
///       responses:
///         200:
///           description: Successful response
///           schema:
///             type: object
///             properties:
///               removed:
///                 description: number of elements removed
///                 type: integer
/// </example>
ClassMethod RemoveStringFromBlacklistPOST(namespace As %String, pDomainId As %Integer, pBlacklistId As %Integer) As %Status [ Internal ]
{
	quit ..RemoveStringFromBlacklist(namespace, pDomainId, pBlacklistId)
}

/// <example language="swagger">
///       summary: |
///         Removes elements from a given blacklist
///       tags: ["Blacklists"]
///       parameters:
///         - $ref: '#/parameters/domainParam'
///         - name: id
///           in: path
///           type: string
///           description: ID of the blacklist to modify
///           required: true
///         - name: string
///           in: path
///           type: string
///           description: element to remove from the blacklist
///           required: true
///         - name: RequestBody
///           description: JSON object with a list of query-specific arguments
///           in: body
///           schema:
///             type: object
///             properties:
///               elements: 
///                 description: if set, overrides what's passed in through the path parameter
///                 type: array
///                 example: []
///                 items:
///                   type: string
/// 
///       responses:
///         200:
///           description: Successful response
///           schema:
///             type: object
///             properties:
///               removed:
///                 description: number of elements removed
///                 type: integer
/// </example>
ClassMethod RemoveStringFromBlacklist(namespace As %String, pDomainId As %Integer, pBlacklistId As %Integer, pElements As %String = "") As %Status
{
	set tSC = $$$OK
	$$$IKRESTINITDEBUG
	try {
		do ..ResolveDomainId(.pDomainId)
		
		
		set tResult = { "removed": 0 }
		
		set tIterator = ..ParseStringArray("elements", $g(pElements)).%GetIterator()
		while tIterator.%GetNext(,.tElem) {
			set tSC = ##class(%iKnow.Utils.MaintenanceAPI).RemoveStringFromBlackList(pDomainId, pBlacklistId, tElem)
			set tResult.removed = tResult.removed + $$$ISOK(tSC)
		}
		
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit ..%ProcessResult(tSC, $g(tResult))
}

/// Simplified version of <method>GetDictionaries</method> for HTTP GET methods
/// <example language="swagger">
///       summary: |
///         Retrieves a list of available dictionaries
///       tags: ["Dictionaries and Matching"]
///       parameters:
///         - $ref: '#/parameters/domainParam'
/// 
///       responses:
///         200:
///           description: Successful response
///           schema:
///             $ref: '#/definitions/DictionaryList'
/// </example>
ClassMethod GetDictionariesGET(namespace As %String, pDomainId As %Integer) As %Status [ Internal ]
{
	quit ..GetDictionaries(namespace, pDomainId)
}

/// <example language="swagger">
///       summary: |
///         Retrieves a list of available dictionaries
///       tags: ["Dictionaries and Matching"]
///       parameters:
///         - $ref: '#/parameters/domainParam'
///         - name: RequestBody
///           description: JSON object with a list of query-specific arguments
///           in: body
///           schema:
///             type: object
///             properties:
///               includeItems:
///                 description: whether or not to include item and term details as well
///                 type: boolean
///                 format: integer
///               includeCount:
///                 $ref: '#/definitions/IncludeCount'
///               countOnly:
///                 $ref: '#/definitions/CountOnly'
/// 
///       responses:
///         200:
///           description: Successful response
///           schema:
///             $ref: '#/definitions/DictionaryList'
/// </example>
ClassMethod GetDictionaries(namespace As %String, pDomainId As %Integer) As %Status
{
	set tSC = $$$OK
	$$$IKRESTINITDEBUG
	try {
		do ..ResolveDomainId(.pDomainId)
		set:'%request.Content.%IsDefined("includeItems") %request.Content.includeItems = 0
		
		set tResult = {}
		
		set tSC = ..ParseArgs(pDomainId, .tPage, .tPageSize)
		quit:$$$ISERR(tSC)
		
		// BDB753
		if (%request.Content.includeCount || %request.Content.countOnly) {
			set tCount = ##class(%iKnow.Matching.DictionaryAPI).GetDictionaryCount(pDomainId, .tSC)
			quit:$$$ISERR(tSC)
			set tResult.count = tCount
		}
		quit:%request.Content.countOnly
		
		set tResult.dictionaries = []
		set tSC = ##class(%iKnow.Matching.DictionaryAPI).GetDictionaries(.tDicts, pDomainId, tPage, tPageSize)
		quit:$$$ISERR(tSC)
		set i = ""
		for {
			set i = $order(tDicts(i), 1, tDictData)
			quit:i=""
			
			set tJSON = { "id": (+$lg(tDictData,1)), "name": ($lg(tDictData,2)), "language": ($lg(tDictData,4)) }
			set:$ld(tDictData,3,tDesc)&&(tDesc'="") tJSON.description = tDesc
			
			do tResult.dictionaries.%Push(tJSON)
			
			continue:'%request.Content.includeItems
			
			$$$IKRESTSTARTTIMER(items)
			set tSC = ##class(%iKnow.Matching.DictionaryAPI).GetDictionaryItems(.tItems, pDomainId, tJSON.id, tPage, tPageSize)
			quit:$$$ISERR(tSC)
			set j = "", tJSON.items = []
			for {
				set j = $order(tItems(j), 1, tItemData)
				quit:j=""
				
				set tJSONI = { "id": (+$lg(tItemData,1)), "name" : ($lg(tItemData,2)), "uri" : ($lg(tItemData,3)) , "language" : ($lg(tItemData,4)) }
				do tJSON.items.%Push(tJSONI)
				
				set tSC = ##class(%iKnow.Matching.DictionaryAPI).GetDictionaryTermsByItem(.tTerms, pDomainId, tJSONI.id, tPage, tPageSize)
				quit:$$$ISERR(tSC)
				set k="", tJSONI.terms = []
				for {
					set k = $order(tTerms(k), 1, tTermData)
					quit:k=""
					
					set tJSONT = { "id": (+$lg(tTermData,1)) }
					if ($lg(tTermData,2)["[") && ($lg(tTermData,2)[".") {
						set tSC = ##class(%iKnow.Matching.DictionaryAPI).GetTermElements(.tElems, pDomainId, tJSONT.id)
						quit:$$$ISERR(tSC)
						set tSC = ##class(%iKnow.Matching.DictionaryAPI).GetFormatDetails(pDomainId, $lg(tElems(1),3), .tClass, .tParams)
						quit:$$$ISERR(tSC)
						set tJSONT.formatClass = tClass
						set tJSONT.formatParams = [], ptr=0
						while $listnext(tParams,ptr,tParam) { do tJSONT.formatParams.%Push(tParam) }
					} else {
						set tJSONT.string = $lg(tTermData,2)
					}
					do tJSONI.terms.%Push(tJSONT)
				 }
			}
			quit:$$$ISERR(tSC)
			$$$IKRESTSTOPTIMER(items)
		}
		
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit ..%ProcessResult(tSC, $g(tResult))
}

/// <example language="swagger">
///       summary: |
///         Retrieves the detailed contents for a given Dictionary
///       tags: ["Dictionaries and Matching"]
///       parameters:
///         - $ref: '#/parameters/domainParam'
///         - name: id
///           description: ID of the dictionary to retrieve
///           in: path
///           type: integer
///           required: true
/// 
///       responses:
///         200:
///           description: Successful response
///           schema:
///             $ref: '#/definitions/DictionaryDetails'
/// </example>
ClassMethod GetDictionaryDetails(namespace As %String, pDomainId As %Integer, pDictionaryId As %Integer) As %Status
{
	set tSC = $$$OK
	$$$IKRESTINITDEBUG
	try {
		do ..ResolveDomainId(.pDomainId)
		
		set tDictObj = ##class(%iKnow.Objects.Dictionary).PKINDEXOpen(pDomainId, pDictionaryId)
		if '$isobject(tDictObj) {
			set tSC = $$$ERROR($$$IKDictionaryDoesNotExist, pDictionaryId)
			quit
		}
		
		set tResult = { "id":(pDictionaryId), "name":(tDictObj.Name), "items": [] }
		set:tDictObj.Description'="" tResult.description = tDictObj.Description
		set tResult.language = tDictObj.DefaultLanguage
		
		set tSC = ..ParseArgs(pDomainId, .tPage, .tPageSize)
		quit:$$$ISERR(tSC)
		
		set tSC = ##class(%iKnow.Matching.DictionaryAPI).GetDictionaryItems(.tItems, pDomainId, pDictionaryId, tPage, tPageSize)
		quit:$$$ISERR(tSC)
		set j = ""
		for {
			set j = $order(tItems(j), 1, tItemData)
			quit:j=""
			
			set tJSONI = { "id": (+$lg(tItemData,1)), "name" : ($lg(tItemData,2)), "uri" : ($lg(tItemData,3)) , "language" : ($lg(tItemData,4)) }
			do tResult.items.%Push(tJSONI)
			
			set tSC = ##class(%iKnow.Matching.DictionaryAPI).GetDictionaryTermsByItem(.tTerms, pDomainId, tJSONI.id, tPage, tPageSize)
			quit:$$$ISERR(tSC)
			set k="", tJSONI.terms = []
			for {
				set k = $order(tTerms(k), 1, tTermData)
				quit:k=""
				
				set tJSONT = { "id": (+$lg(tTermData,1)) }
				if ($lg(tTermData,2)["[") && ($lg(tTermData,2)[".") {
					set tSC = ##class(%iKnow.Matching.DictionaryAPI).GetTermElements(.tElems, pDomainId, tJSONT.id)
					quit:$$$ISERR(tSC)
					set tSC = ##class(%iKnow.Matching.DictionaryAPI).GetFormatDetails(pDomainId, $lg(tElems(1),3), .tClass, .tParams)
					quit:$$$ISERR(tSC)
					set tJSONT.formatClass = tClass
					set tJSONT.formatParams = [], ptr=0
					while $listnext(tParams,ptr,tParam) { do tJSONT.formatParams.%Push(tParam) }
				} else {
					set tJSONT.string = $lg(tTermData,2)
				}
				do tJSONI.terms.%Push(tJSONT)
			 }
			 quit:$$$ISERR(tSC)
		}
		
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit ..%ProcessResult(tSC, $g(tResult))
}

/// <example language="swagger">
///       summary: |
///         Drops a dictionary
///       tags: ["Dictionaries and Matching"]
///       parameters:
///         - $ref: '#/parameters/domainParam'
///         - name: id
///           description: ID of the dictionary to drop
///           in: path
///           type: integer
///           required: true
/// 
///       responses:
///         200:
///           description: Successful response
///           schema:
///             type: object
///             properties:
///               dropped:
///                 type: boolean
///                 format: integer
/// </example>
ClassMethod DropDictionary(namespace As %String, pDomainId As %Integer, pDictionaryId As %Integer) As %Status
{
	set tSC = $$$OK
	$$$IKRESTINITDEBUG
	try {
		do ..ResolveDomainId(.pDomainId)
		
		set tDictObj = ##class(%iKnow.Objects.Dictionary).PKINDEXOpen(pDomainId, pDictionaryId)
		if '$isobject(tDictObj) {
			set tSC = $$$ERROR($$$IKDictionaryDoesNotExist, pDictionaryId)
			quit
		}
		
		set tSC = ##class(%iKnow.Matching.DictionaryAPI).DropDictionary(pDomainId, pDictionaryId)
		set tResult = { "dropped" : ($$$ISOK(tSC)) }
		quit:$$$ISERR(tSC)
		
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit ..%ProcessResult(tSC, $g(tResult))
}

/// Simplified version of <method>CreateDictionary</method> for HTTP GET requests
/// <example language="swagger">
///       summary: |
///         Create a new dictionary
///       tags: ["Dictionaries and Matching"]
///       parameters:
///         - $ref: '#/parameters/domainParam'
///         - name: name
///           description: name for the new dictionary
///           in: path
///           type: string
///           required: true
/// 
///       responses:
///         200:
///           description: Successful response
///           schema:
///             allOf:
///               - $ref: '#/definitions/DictionaryDetails'
///               - type: object
///                 properties:
///                   created:
///                     type: boolean
///                     format: integer
///                     default: 1
///                   matched:
///                     type: boolean
///                     format: integer
/// </example>
ClassMethod CreateDictionaryGET(namespace As %String, pDomainId As %Integer, pName As %String = "") As %Status [ Internal ]
{
	quit ..CreateDictionary(namespace, pDomainId, pName)
}

/// Simplified version of <method>CreateDictionary</method> for HTTP POST requests
/// <example language="swagger">
///       summary: |
///         Create a new dictionary
///       tags: ["Dictionaries and Matching"]
///       parameters:
///         - $ref: '#/parameters/domainParam'
///         - name: RequestBody
///           description: JSON object with a list of query-specific arguments
///           in: body
///           required: true
///           schema:
///             type: object
///             required: ["name"]
///             properties:
///               name:
///                 description: name for the new dictionary
///                 type: string
///               description:
///                 type: string
///               language:
///                 description: default language for dictionary entries
///                 $ref: '#/definitions/LanguageCode'
///               items:
///                 description: list of items to add (don't supply id values)
///                 type: array
///                 items:
///                   $ref: '#/definitions/DictionaryItemDetails'
///               match:
///                 description: if set to true, the dictionary is immediately matched against the domain's sources
///                 type: boolean
///                 format: integer
///               filter:
///                 description: if match=1, restricts the sources to be matched
///                 $ref: '#/definitions/Filter'
/// 
///       responses:
///         200:
///           description: Successful response
///           schema:
///             allOf:
///               - $ref: '#/definitions/DictionaryDetails'
///               - type: object
///                 properties:
///                   created:
///                     type: boolean
///                     format: integer
///                     default: 1
///                   matched:
///                     type: boolean
///                     format: integer
/// </example>
ClassMethod CreateDictionaryPOST(namespace As %String, pDomainId As %Integer) As %Status [ Internal ]
{
	quit ..CreateDictionary(namespace, pDomainId)
}

/// <example language="swagger">
///       summary: |
///         Create a new dictionary
///       tags: ["Dictionaries and Matching"]
///       parameters:
///         - $ref: '#/parameters/domainParam'
///         - name: name
///           description: name for the new dictionary
///           in: path
///           type: string
///           required: true
///         - name: RequestBody
///           description: JSON object with a list of query-specific arguments
///           in: body
///           schema:
///             type: object
///             properties:
///               name:
///                 description: if provided, overrides the path parameter
///                 type: string
///               description:
///                 type: string
///               language:
///                 description: default language for dictionary entries
///                 $ref: '#/definitions/LanguageCode'
///               items:
///                 description: list of items to add (don't supply id values)
///                 type: array
///                 items:
///                   $ref: '#/definitions/DictionaryItemDetails'
///               match:
///                 description: if set to true, the dictionary is immediately matched against the domain's sources
///                 type: boolean
///                 format: integer
///               filter:
///                 description: if match=1, restricts the sources to be matched
///                 $ref: '#/definitions/Filter'
/// 
///       responses:
///         200:
///           description: Successful response
///           schema:
///             allOf:
///               - $ref: '#/definitions/DictionaryDetails'
///               - type: object
///                 properties:
///                   created:
///                     type: boolean
///                     format: integer
///                     default: 1
///                   matched:
///                     type: boolean
///                     format: integer
/// </example>
ClassMethod CreateDictionary(namespace As %String, pDomainId As %Integer, pName As %String = "") As %Status
{
	set tSC = $$$OK
	$$$IKRESTINITDEBUG
	try {
		do ..ResolveDomainId(.pDomainId)
		set:%request.Content.%IsDefined("name") pName = %request.Content.name
		
		set tDictId = ##class(%iKnow.Matching.DictionaryAPI).CreateDictionary(pDomainId, pName, %request.Content.description, $s(%request.Content.language="":"en", 1:%request.Content.language),, .tSC)
		set tResult = { "created" : ($$$ISOK(tSC)) }
		quit:$$$ISERR(tSC)
			
		set tResult.id = tDictId, tResult.name = pName
		
		if %request.Content.%IsDefined("items") {
			set tIterator = %request.Content.items.%GetIterator()
			set tResult.items = []
			while tIterator.%GetNext(,.tItem) {
				set tURI = tItem.uri
				set tItemId = ##class(%iKnow.Matching.DictionaryAPI).CreateDictionaryItem(pDomainId, tDictId, tItem.name, .tURI, $s(tItem.language="":"en", 1:tItem.language), .tSC)
				if $$$ISERR(tSC) {
					set tItem.error = $system.Status.GetErrorText(tSC)
				} else {
					set tItem.id = tItemId, tItem.uri = tURI
					
					if tItem.%IsDefined("terms") {
						set tIterator2 = tItem.terms.%GetIterator(), pos=0
						while tIterator2.%GetNext(,.tTerm) {
							if '$isobject(tTerm) {
								set tTerm = { "string": (tTerm) }
								do tItem.terms.%SetAt(pos, tTerm)
							}
							set pos = pos+1
							if (tTerm.string'="") {
								set tTermId = ##class(%iKnow.Matching.DictionaryAPI).CreateDictionaryTerm(pDomainId, tItemId, tTerm.string, $s(tTerm.language="":"en", 1:tTerm.language), .tSC)
							} elseif (tTerm.regexp'="") {
								set tTermId = ##class(%iKnow.Matching.DictionaryAPI).CreateRegularExpression(pDomainId, tItemId, tTerm.regexp, tTerm.replace, .tSC)
							} elseif (tTerm.formatClass'="") {
								set tParams = ""
								if tTerm.%IsDefined("formatParameters") {
									set tIt3 = tTerm.formatParameters.%GetIterator()
									while tIt3.%GetNext(,.tParam) { set tParams = tParams_$lb(tParam) }
								}
								set tTermId = ##class(%iKnow.Matching.DictionaryAPI).CreateDictionaryTermFormat(pDomainId, tItemId, tTerm.formatClass, tParams, .tSC)
							} else {
								set tSC = $$$ERROR($$$GeneralError, "Unknown term specification")
							}
							if $$$ISERR(tSC) {
								set tTerm.error = $system.Status.GetErrorText(tSC)
							} else {
								set tTerm.id = tTermId
							}
						}
					}
				}
				do tResult.items.%Push(tItem)
			}
		}
		
		if %request.Content.match {
			$$$IKRESTSTARTTIMER(matching)
			set tSC = ..ParseArgs(pDomainId,,, .tFilter)
			quit:$$$ISERR(tSC)
			set tSC = ##class(%iKnow.Matching.MatchingAPI).MatchSources(pDomainId, tFilter, $lb(tDictId))
			set tResult.matched = $$$ISOK(tSC)
			quit:$$$ISERR(tSC)
			$$$IKRESTSTOPTIMER(matching)
		}
		
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit ..%ProcessResult(tSC, $g(tResult))
}

/// <example language="swagger">
///       summary: |
///         Retrieves the detailed contents for a given Dictionary Item
///       tags: ["Dictionaries and Matching"]
///       parameters:
///         - $ref: '#/parameters/domainParam'
///         - name: id
///           description: ID or URI of the dictionary item to retrieve
///           in: path
///           type: integer
///           required: true
/// 
///       responses:
///         200:
///           description: Successful response
///           schema:
///             allOf:
///               - $ref: '#/definitions/DictionaryItemDetails'
///               - type: object
///                 properties:
///                   dictionary:
///                     type: object
///                     properties:
///                       id: 
///                         type: integer
///                       name:
///                         type: string
/// </example>
ClassMethod GetDictionaryItemDetails(namespace As %String, pDomainId As %Integer, pDictionaryItemId As %Integer) As %Status
{
	set tSC = $$$OK
	$$$IKRESTINITDEBUG
	try {
		do ..ResolveDomainId(.pDomainId)
		
		// accept URIs too
		if '$isvalidnum(pDictionaryItemId) {
			set tItemId = ##class(%iKnow.Matching.DictionaryAPI).GetDictionaryItemIdByURI(pDomainId,pDictionaryItemId, .tSC)
			quit:tItemId<=0
			set pDictionaryItemId = tItemId
		}
		
		set tItemObj = ##class(%iKnow.Objects.DictionaryItem).PKINDEXOpen(pDomainId, pDictionaryItemId)
		if '$isobject(tItemObj) {
			set tSC = $$$ERROR($$$IKDictItemDoesNotExist, pDictionaryItemId)
			quit
		}
		
		set tResult = { "id":(pDictionaryItemId), "name":(tItemObj.Name), "uri": (tItemObj.URI), "language":(tItemObj.DefaultLanguage),
							"dictionary": { "id": (tItemObj.DictionaryId), "name": (tItemObj.Dictionary.Name) },
							"terms": [] }
		set:tItemObj.Dictionary.Description'="" tResult.dictionary.description = tItemObj.Dictionary.Description
		
		set tSC = ..ParseArgs(pDomainId, .tPage, .tPageSize)
		quit:$$$ISERR(tSC)
		
		set tSC = ##class(%iKnow.Matching.DictionaryAPI).GetDictionaryTermsByItem(.tTerms, pDomainId, pDictionaryItemId, tPage, tPageSize)
		quit:$$$ISERR(tSC)
		set k=""
		for {
			set k = $order(tTerms(k), 1, tTermData)
			quit:k=""
			
			set tJSONT = { "id": (+$lg(tTermData,1)) }
			if ($lg(tTermData,2)["[") && ($lg(tTermData,2)[".") {
				set tSC = ##class(%iKnow.Matching.DictionaryAPI).GetTermElements(.tElems, pDomainId, tJSONT.id)
				quit:$$$ISERR(tSC)
				set tSC = ##class(%iKnow.Matching.DictionaryAPI).GetFormatDetails(pDomainId, $lg(tElems(1),3), .tClass, .tParams)
				quit:$$$ISERR(tSC)
				set tJSONT.formatClass = tClass
				set tJSONT.formatParams = [], ptr=0
				while $listnext(tParams,ptr,tParam) { do tJSONT.formatParams.%Push(tParam) }
			} else {
				set tJSONT.string = $lg(tTermData,2)
			}
			do tResult.terms.%Push(tJSONT)
		}
		
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit ..%ProcessResult(tSC, $g(tResult))
}

/// <example language="swagger">
///       summary: |
///         Drops a dictionary item
///       tags: ["Dictionaries and Matching"]
///       parameters:
///         - $ref: '#/parameters/domainParam'
///         - name: id
///           description: ID or URI of the dictionary item to drop
///           in: path
///           type: integer
///           required: true
/// 
///       responses:
///         200:
///           description: Successful response
///           schema:
///             type: object
///             properties:
///               dropped:
///                 type: boolean
///                 format: integer
/// </example>
ClassMethod DropDictionaryItem(namespace As %String, pDomainId As %Integer, pDictionaryItemId As %Integer) As %Status
{
	set tSC = $$$OK
	$$$IKRESTINITDEBUG
	try {
		do ..ResolveDomainId(.pDomainId)
		
		// accept URIs too
		if '$isvalidnum(pDictionaryItemId) {
			set tItemId = ##class(%iKnow.Matching.DictionaryAPI).GetDictionaryItemIdByURI(pDomainId,pDictionaryItemId, .tSC)
			quit:tItemId<=0
			set pDictionaryItemId = tItemId
		}
		
		set tItemObj = ##class(%iKnow.Objects.DictionaryItem).PKINDEXOpen(pDomainId, pDictionaryItemId)
		if '$isobject(tItemObj) {
			set tSC = $$$ERROR($$$IKDictItemDoesNotExist, pDictionaryItemId)
			quit
		}
		
		set tResult = { "dropped" : 0 }
		
		set tSC = ##class(%iKnow.Matching.DictionaryAPI).DropDictionaryItem(pDomainId, pDictionaryItemId)
		set tResult = { "dropped" : ($$$ISOK(tSC)) }
		
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit ..%ProcessResult(tSC, $g(tResult))
}

/// Simplified version of <method>CreateDictionaryItems</method> for HTTP POST requests
/// <example language="swagger">
///       summary: |
///         Create new dictionary items
///       tags: ["Dictionaries and Matching"]
///       parameters:
///         - $ref: '#/parameters/domainParam'
///         - name: RequestBody
///           description: JSON object with a list of query-specific arguments
///           in: body
///           required: true
///           schema:
///             type: object
///             required: ["dictionaryId", "items"]
///             properties:
///               dictionaryId:
///                 description: if provided, overrides the path parameter
///                 type: string
///               items:
///                 description: list of items to add (don't supply id values)
///                 type: array
///                 items:
///                   $ref: '#/definitions/DictionaryItemDetails'
///               match:
///                 description: if set to true, the dictionary is immediately matched against the domain's sources
///                 type: boolean
///                 format: integer
///               filter:
///                 description: if match=1, restricts the sources to be matched
///                 $ref: '#/definitions/Filter'
/// 
///       responses:
///         200:
///           description: Successful response
///           schema:
///             title: AddItemsResult
///             type: object
///             properties:
///               dictionary:
///                 type: object
///                 title: DictionaryDetails
///                 description: the dictionary these items were added to
///                 properties:
///                   id:
///                     type: integer
///                   name:
///                     type: string
///               items:
///                 type: array
///                 items:
///                   allOf:
///                     - $ref: '#/definitions/DictionaryItemDetails'
///                     - type: object
///                       properties:
///                         error:
///                           description: the error message, if this item failed to get created
///                           type: string
///               matched:
///                 type: boolean
///                 format: integer
/// </example>
ClassMethod CreateDictionaryItemsPOST(namespace As %String, pDomainId As %Integer) As %Status
{
	quit ..CreateDictionaryItems(namespace, pDomainId)
}

/// <example language="swagger">
///       summary: |
///         Create new dictionary items
///       tags: ["Dictionaries and Matching"]
///       parameters:
///         - $ref: '#/parameters/domainParam'
///         - name: id
///           description: ID of the dictionary to which to add the new item
///           in: path
///           type: string
///           required: true
///         - name: RequestBody
///           description: JSON object with a list of query-specific arguments
///           in: body
///           required: true
///           schema:
///             type: object
///             properties:
///               dictionaryId:
///                 description: if provided, overrides the path parameter
///                 type: string
///               items:
///                 description: list of items to add (don't supply id values)
///                 type: array
///                 items:
///                   $ref: '#/definitions/DictionaryItemDetails'
///               match:
///                 description: if set to true, the dictionary is immediately matched against the domain's sources
///                 type: boolean
///                 format: integer
///               filter:
///                 description: if match=1, restricts the sources to be matched
///                 $ref: '#/definitions/Filter'
/// 
///       responses:
///         200:
///           description: Successful response
///           schema:
///             title: AddItemsResult
///             type: object
///             properties:
///               dictionary:
///                 type: object
///                 title: DictionaryDetails
///                 description: the dictionary these items were added to
///                 properties:
///                   id:
///                     type: integer
///                   name:
///                     type: string
///               items:
///                 type: array
///                 items:
///                   allOf:
///                     - $ref: '#/definitions/DictionaryItemDetails'
///                     - type: object
///                       properties:
///                         error:
///                           description: the error message, if this item failed to get created
///                           type: string
///               matched:
///                 type: boolean
///                 format: integer
/// </example>
ClassMethod CreateDictionaryItems(namespace As %String, pDomainId As %Integer, pDictionaryId As %Integer = 0) As %Status
{
	set tSC = $$$OK
	$$$IKRESTINITDEBUG
	try {
		do ..ResolveDomainId(.pDomainId)
		set:%request.Content.%IsDefined("dictionaryId") pDictionaryId = %request.Content.dictionaryId
		
		if '$isobject(%request.Content.items) {
			set tSC = $$$ERROR($$$GeneralError, "Invalid request format. Items need to be an object or array thereof")
			quit
		}
		set:'%request.Content.items.%IsA("%DynamicArray") %request.Content.items = [ (%request.Content.items) ]
		
		set tDictObj = ##class(%iKnow.Objects.Dictionary).PKINDEXOpen(pDomainId, pDictionaryId)
		if '$isobject(tDictObj) {
			set tSC = $$$ERROR($$$IKDictionaryDoesNotExist, pDictionaryId)
			quit
		}
		
		set tResult = { "dictionary": { "id": (pDictionaryId), "name": (tDictObj.Name) }, "items" : [] }
		set tIterator = %request.Content.items.%GetIterator()
		while tIterator.%GetNext(,.tItem) {
			set tURI = tItem.uri
			set tItemId = ##class(%iKnow.Matching.DictionaryAPI).CreateDictionaryItem(pDomainId, pDictionaryId, tItem.name, .tURI, $s(tItem.language="":"en", 1:tItem.language), .tSC)
			if $$$ISERR(tSC) {
				set tItem.error = $system.Status.GetErrorText(tSC)
			} else {
				set tItem.id = tItemId, tItem.uri = tURI
				
				if tItem.%IsDefined("terms") {
					set tIterator2 = tItem.terms.%GetIterator(), pos=0
					while tIterator2.%GetNext(,.tTerm) {
						if '$isobject(tTerm) {
							set tTerm = { "string": (tTerm) }
							do tItem.terms.%SetAt(pos, tTerm)
						}
						set pos = pos+1
						if (tTerm.string'="") {
							set tTermId = ##class(%iKnow.Matching.DictionaryAPI).CreateDictionaryTerm(pDomainId, tItemId, tTerm.string, $s(tTerm.language="":"en", 1:tTerm.language), .tSC)
						} elseif (tTerm.regexp'="") {
							set tTermId = ##class(%iKnow.Matching.DictionaryAPI).CreateRegularExpression(pDomainId, tItemId, tTerm.regexp, tTerm.replace, .tSC)
						} elseif (tTerm.formatClass'="") {
							set tParams = ""
							if tTerm.%IsDefined("formatParameters") {
								set tIt3 = tTerm.formatParameters.%GetIterator()
								while tIt3.%GetNext(,.tParam) { set tParams = tParams_$lb(tParam) }
							}
							set tTermId = ##class(%iKnow.Matching.DictionaryAPI).CreateDictionaryTermFormat(pDomainId, tItemId, tTerm.formatClass, tParams, .tSC)
						} else {
							set tSC = $$$ERROR($$$GeneralError, "Unknown term specification")
						}
						if $$$ISERR(tSC) {
							set tTerm.error = $system.Status.GetErrorText(tSC)
						} else {
							set tTerm.id = tTermId
						}
					}
				}
			}
			do tResult.items.%Push(tItem)
		}
		
		if %request.Content.match {
			$$$IKRESTSTARTTIMER(matching)
			set tSC = ..ParseArgs(pDomainId,,, .tFilter)
			quit:$$$ISERR(tSC)
			set tSC = ##class(%iKnow.Matching.MatchingAPI).MatchSources(pDomainId, tFilter, $lb(pDictionaryId))
			set tResult.matched = $$$ISOK(tSC)
			quit:$$$ISERR(tSC)
			$$$IKRESTSTOPTIMER(matching)
		}
		
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit ..%ProcessResult(tSC, $g(tResult))
}

/// Simplified version of <method>CreateDictionaryTerms</method> for HTTP POST requests.
/// <example language="swagger">
///       summary: |
///         Create new dictionary terms
///       tags: ["Dictionaries and Matching"]
///       parameters:
///         - $ref: '#/parameters/domainParam'
///         - name: RequestBody
///           description: JSON object with a list of query-specific arguments
///           in: body
///           required: true
///           schema:
///             type: object
///             required: ["dictionaryItemId", "terms"]
///             properties:
///               dictionaryItemId:
///                 description: if provided, overrides the corresponding path parameter
///                 type: string
///               terms:
///                 description: list of terms to add (don't supply id values). An array of strings will be interpreted as simple terms.
///                 type: array
///                 items:
///                   $ref: '#/definitions/DictionaryTermDetails'
///               match:
///                 description: if set to true, the dictionary is immediately matched against the domain's sources
///                 type: boolean
///                 format: integer
///               filter:
///                 description: if match=1, restricts the sources to be matched
///                 $ref: '#/definitions/Filter'
/// 
///       responses:
///         200:
///           description: Successful response
///           schema:
///             title: AddTermsResult
///             type: object
///             properties:
///               item:
///                 type: object
///                 title: DictionaryItemDetails
///                 description: the dictionary item these terms were added to
///                 properties:
///                   id:
///                     type: integer
///                   name:
///                     type: string
///                   uri:
///                     type: string
///                   dictionary:
///                     type: object
///                     title: DictionaryDetails
///                     description: the dictionary these terms were added to
///                     properties:
///                       id:
///                         type: integer
///                       name:
///                         type: string
///               terms:
///                 type: array
///                 items:
///                   allOf:
///                     - $ref: '#/definitions/DictionaryTermDetails'
///                     - type: object
///                       properties:
///                         error:
///                           description: the error message, if this term failed to get created
///                           type: string
///               matched:
///                 type: boolean
///                 format: integer
/// </example>
ClassMethod CreateDictionaryTermsPOST(namespace As %String, pDomainId As %Integer, pDictionaryItemId As %Integer = 0) As %Status [ Internal ]
{
	quit ..CreateDictionaryTerms(namespace, pDomainId)
}

/// <example language="swagger">
///       summary: |
///         Create new dictionary terms
///       tags: ["Dictionaries and Matching"]
///       parameters:
///         - $ref: '#/parameters/domainParam'
///         - name: id
///           description: ID or URI of the dictionary item to which to add the new terms
///           in: path
///           type: string
///           required: true
///         - name: RequestBody
///           description: JSON object with a list of query-specific arguments
///           in: body
///           required: true
///           schema:
///             type: object
///             properties:
///               dictionaryItemId:
///                 description: if provided, overrides the corresponding path parameter
///                 type: string
///               terms:
///                 description: list of terms to add (don't supply id values). An array of strings will be interpreted as simple terms.
///                 type: array
///                 items:
///                   $ref: '#/definitions/DictionaryTermDetails'
///               match:
///                 description: if set to true, the dictionary is immediately matched against the domain's sources
///                 type: boolean
///                 format: integer
///               filter:
///                 description: if match=1, restricts the sources to be matched
///                 $ref: '#/definitions/Filter'
/// 
///       responses:
///         200:
///           description: Successful response
///           schema:
///             title: AddTermsResult
///             type: object
///             properties:
///               item:
///                 type: object
///                 title: DictionaryItemDetails
///                 description: the dictionary item these terms were added to
///                 properties:
///                   id:
///                     type: integer
///                   name:
///                     type: string
///                   uri:
///                     type: string
///                   dictionary:
///                     type: object
///                     title: DictionaryDetails
///                     description: the dictionary these terms were added to
///                     properties:
///                       id:
///                         type: integer
///                       name:
///                         type: string
///               terms:
///                 type: array
///                 items:
///                   allOf:
///                     - $ref: '#/definitions/DictionaryTermDetails'
///                     - type: object
///                       properties:
///                         error:
///                           description: the error message, if this term failed to get created
///                           type: string
///               matched:
///                 type: boolean
///                 format: integer
/// </example>
ClassMethod CreateDictionaryTerms(namespace As %String, pDomainId As %Integer, pDictionaryItemId As %Integer = 0) As %Status
{
	set tSC = $$$OK
	$$$IKRESTINITDEBUG
	try {
		do ..ResolveDomainId(.pDomainId)
		set:%request.Content.%IsDefined("dictionaryItemId") pDictionaryItemId = +%request.Content.dictionaryItemId
		
		if ('$isobject(%request.Content.terms)) || ('%request.Content.terms.%IsA("%DynamicArray")) {
			set %request.Content.terms = [ (%request.Content.terms) ]
		}
		
		// accept URIs too
		if '$isvalidnum(pDictionaryItemId) {
			set tItemId = ##class(%iKnow.Matching.DictionaryAPI).GetDictionaryItemIdByURI(pDomainId,pDictionaryItemId, .tSC)
			quit:tItemId<=0
			set pDictionaryItemId = tItemId
		}
		
		set tDictItemObj = ##class(%iKnow.Objects.DictionaryItem).PKINDEXOpen(pDomainId, pDictionaryItemId)
		if '$isobject(tDictItemObj) {
			set tSC = $$$ERROR($$$IKDictItemDoesNotExist, pDictionaryItemId)
			quit
		}
		
		set tResult = { "item": { "id": (pDictionaryItemId), "name": (tDictItemObj.Name), "uri": (tDictItemObj.URI) }, "terms" : [] }
		set tResult.item.dictionary = { "id": (tDictItemObj.DictionaryId), "name": (tDictItemObj.Dictionary.Name) }
		set tIterator = %request.Content.terms.%GetIterator()
		while tIterator.%GetNext(,.tTerm) {
			if '$isobject(tTerm) {
				set tTerm = { "string": (tTerm) }
			}
			if (tTerm.string'="") {
				set tTermId = ##class(%iKnow.Matching.DictionaryAPI).CreateDictionaryTerm(pDomainId, pDictionaryItemId, tTerm.string, $s(tTerm.language="":"en", 1:tTerm.language), .tSC)
			} elseif (tTerm.regexp'="") {
				set tTermId = ##class(%iKnow.Matching.DictionaryAPI).CreateRegularExpression(pDomainId, pDictionaryItemId, tTerm.regexp, tTerm.replace, .tSC)
			} elseif (tTerm.formatClass'="") {
				set tParams = ""
				if tTerm.%IsDefined("formatParameters") {
					set tIt3 = tTerm.formatParameters.%GetIterator()
					while tIt3.%GetNext(,.tParam) { set tParams = tParams_$lb(tParam) }
				}
				set tTermId = ##class(%iKnow.Matching.DictionaryAPI).CreateDictionaryTermFormat(pDomainId, pDictionaryItemId, tTerm.formatClass, tParams, .tSC)
			} else {
				set tSC = $$$ERROR($$$GeneralError, "Unknown term specification")
			}
			if $$$ISERR(tSC) {
				set tTerm.error = $system.Status.GetErrorText(tSC)
			} else {
				set tTerm.id = tTermId
			}
			do tResult.terms.%Push(tTerm)
		}
		
		if %request.Content.match {
			$$$IKRESTSTARTTIMER(matching)
			set tSC = ..ParseArgs(pDomainId,,, .tFilter)
			quit:$$$ISERR(tSC)
			set tSC = ##class(%iKnow.Matching.MatchingAPI).MatchSources(pDomainId, tFilter, $lb(tDictItemObj.DictionaryId))
			set tResult.matched = $$$ISOK(tSC)
			quit:$$$ISERR(tSC)
			$$$IKRESTSTOPTIMER(matching)
		}
		
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit ..%ProcessResult(tSC, $g(tResult))
}

/// <example language="swagger">
///       summary: |
///         Drops a dictionary term
///       tags: ["Dictionaries and Matching"]
///       parameters:
///         - $ref: '#/parameters/domainParam'
///         - name: id
///           description: ID of the dictionary term to drop
///           in: path
///           type: integer
///           required: true
/// 
///       responses:
///         200:
///           description: Successful response
///           schema:
///             type: object
///             properties:
///               dropped:
///                 type: boolean
///                 format: integer
/// </example>
ClassMethod DropDictionaryTerm(namespace As %String, pDomainId As %Integer, pDictionaryTermId As %Integer) As %Status
{
	set tSC = $$$OK
	$$$IKRESTINITDEBUG
	try {
		do ..ResolveDomainId(.pDomainId)
		
		set tDictObj = ##class(%iKnow.Objects.DictionaryTerm).PKINDEXOpen(pDomainId, pDictionaryTermId)
		if '$isobject(tDictObj) {
			set tSC = $$$ERROR($$$IKDictTermDoesNotExist, pDictionaryTermId)
			quit
		}
		
		set tResult = { "dropped" : 0 }
		
		set tSC = ##class(%iKnow.Matching.DictionaryAPI).DropDictionaryTerm(pDomainId, pDictionaryTermId)
		set tResult.dropped = $$$ISOK(tSC)
		
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit ..%ProcessResult(tSC, $g(tResult))
}

/// Simplified version of <method>GetMatchesBySource</method> for HTTP GET requests.
/// <example language="swagger">
///       summary: |
///         Retrieves all dictionary matches for a given source
///       tags: ["Dictionaries and Matching"]
///       parameters:
///         - $ref: '#/parameters/domainParam'
///         - name: id
///           description: the source ID to query for
///           in: path
///           required: true
///           type: integer
/// 
///       responses:
///         200:
///           description: Successful response
///           schema:
///             $ref: '#/definitions/MatchList'
/// </example>
ClassMethod GetMatchesBySourceGET(namespace As %String, pDomainId As %Integer, pSourceId As %Integer) As %Status [ Internal ]
{
	quit ..GetMatchesBySource(namespace, pDomainId, pSourceId)
}

/// <example language="swagger">
///       summary: |
///         Retrieves all dictionary matches for a given source
///       tags: ["Dictionaries and Matching"]
///       parameters:
///         - $ref: '#/parameters/domainParam'
///         - name: id
///           description: the source ID to query for
///           in: path
///           required: true
///           type: integer
///         - name: RequestBody
///           description: JSON object with a list of query-specific arguments
///           in: body
///           schema:
///             type: object
///             properties:
///               page:
///                 $ref: '#/definitions/PageNumber'
///               pageSize:
///                 $ref: '#/definitions/PageSize'
///               matchFirst:
///                 description: ensures this source is matched against the latest dictionaries before retrieving results
///                 type: boolean
///                 format: integer
///                 default: 1
///               dictionaries:
///                 description: if set, limits results to these dictionary IDs
///                 default: []
///                 type: array
///                 items:
///                   type: integer
///               includeDictionaryDetails:
///                 description: whether or not to retrieve dictionary details as well
///                 type: boolean
///                 format: integer
///                 default: 1
///               includeMatchDetails:
///                 description: whether or not to retrieve entity-level match details as well
///                 type: boolean
///                 format: integer
///                 default: 0
///               includeSnippets:
///                 description: whether or not to include the text of the matched sentence
///                 type: boolean
///                 format: integer
///                 default: 1
///               highlight:
///                 $ref: '#/definitions/Highlighting'
/// 
///       responses:
///         200:
///           description: Successful response
///           schema:
///             $ref: '#/definitions/MatchList'
/// </example>
ClassMethod GetMatchesBySource(namespace As %String, pDomainId As %Integer, pSourceId As %Integer) As %Status
{
	set tSC = $$$OK
	$$$IKRESTINITDEBUG
	try {
		do ..ResolveDomainId(.pDomainId)
		set tMatchFirst = $s(%request.Content.%IsDefined("matchFirst"):%request.Content.matchFirst, 1:1)
		set tIncludeDictDetails = $s(%request.Content.%IsDefined("includeDictionaryDetails"):%request.Content.includeDictionaryDetails, 1:1)
		set tIncludeMatchDetails = $s(%request.Content.%IsDefined("includeMatchDetails"):%request.Content.includeMatchDetails, 1:0)
		set tIncludeSnippets = $s(%request.Content.%IsDefined("includeSnippets"):%request.Content.includeSnippets, 1:1)
	
		$$$CHECKASRCIDEXISTSX(pDomainId,pSourceId,tSrcDetails,vSrcId,tSC)
		
		set tDictionaries = ..ParseList("dictionaries")
		set tSC = ..ParseArgs(pDomainId, .tPage, .tPageSize)
		quit:$$$ISERR(tSC)
		set:tIncludeSnippets tSC = ..ParseHighlight(.tHighlight)
		quit:$$$ISERR(tSC)
		
		if (tMatchFirst) {
			$$$IKRESTSTARTTIMER(matching)
			set tSC = ##class(%iKnow.Matching.MatchingAPI).MatchSource(pDomainId, pSourceId, tDictionaries)
			quit:$$$ISERR(tSC)
			$$$IKRESTSTOPTIMER(matching)
		}
		
		set tResult = { "matches": [] }
		set tSC = ##class(%iKnow.Matching.MatchingAPI).GetMatchesBySourceId(.tMatches, pDomainId, pSourceId, tDictionaries, tPage, tPageSize)
		quit:$$$ISERR(tSC)
		set i = ""
		for {
			set i = $order(tMatches(i), 1, tMatchData)
			quit:i=""
			
			set tJSON = { "id": (+$lg(tMatchData,1)), "score": (+$normalize($lg(tMatchData,8),4)), "partialCount": (+$lg(tMatchData,11)), "ordered":(+$lg(tMatchData,14)), "negatedCount": (+$lg(tMatchData,15)) }
			
			set tJSON.term = { "id": (+$lg(tMatchData,5)) }
			
			// BDB734
			set tCrossDomainDict = (tJSON.term.id < 0)
			set tDictDomainId = $s(tCrossDomainDict:0, 1:pDomainId)
			
			if (tIncludeDictDetails) {
				set tTermObj = ##class(%iKnow.Objects.DictionaryTerm).PKINDEXOpen(tDictDomainId, $zabs($lg(tMatchData,5)))
				if (tTermObj.String["[") && (tTermObj.String[".") {
					set tSC = ##class(%iKnow.Matching.DictionaryAPI).GetTermElements(.tElems, tDictDomainId, tTermObj.DictionaryTermId)
					quit:$$$ISERR(tSC)
					set tSC = ##class(%iKnow.Matching.DictionaryAPI).GetFormatDetails(tDictDomainId, $lg(tElems(1),3), .tClass, .tParams)
					quit:$$$ISERR(tSC)
					set tJSON.term.formatClass = tClass
					set tJSON.term.formatParams = [], ptr=0
					while $listnext(tParams,ptr,tParam) { do tJSON.term.formatParams.%Push(tParam) }
				} else {
					set tJSON.term.string = tTermObj.String
				}
				set tJSON.term.item = { "id": (+$lg(tMatchData,3)), "uri": ($lg(tMatchData,4)), "name": (tTermObj.DictionaryItem.Name) }
				set tJSON.term.item.dictionary = { "id": (+$lg(tMatchData,2)), "name": (tTermObj.Dictionary.Name) }
			} else {
				set tJSON.term.item = { "id": (+$lg(tMatchData,3)), "uri": ($lg(tMatchData,4)) }
				set tJSON.term.item.dictionary = { "id": (+$lg(tMatchData,2)) }
			}
			
			set tJSON.sentenceId = ##class(%iKnow.Matching.MatchingAPI).GetSentenceIdForMatchTarget(pDomainId, $lg(tMatchData,6), $lg(tMatchData,7), vSrcId)
			set tJSON.target = { "id": (+$lg(tMatchData,7)) }
			set tJSON.target.type = $case($lg(tMatchData,6), $$$DMTARGETENTITY:"entity", $$$DMTARGETCRC:"crc", $$$DMTARGETPATH:"path", $$$DMTARGETSENT:"sentence")
			
			do tResult.matches.%Push(tJSON)
			
			if (tIncludeMatchDetails) {
				$$$IKRESTSTARTTIMER(details)
				set tSC = ##class(%iKnow.Matching.MatchingAPI).GetMatchElements(.tElems, pDomainId, tJSON.id, vSrcId)
				quit:$$$ISERR(tSC)
				set j="", tJSON.elements=[]
				for {
					set j = $order(tElems(j), 1, tElemData)
					quit:j=""
					set tJSONE = { "partId": (+$lg(tElemData,2)), "literal": ($lg(tElemData,4)), "score": (+$normalize($lg(tElemData,6),4)), "matchedWords": ($lg(tElemData,9)), "negated":(+$lg(tElemData,12)) }
					set:$lg(tElemData,3) tJSONE.entityId = +$lg(tElemData,3), tJSONE.entity = ##class(%iKnow.Queries.EntityAPI).GetValueInternal(pDomainId, tJSONE.entityId, vSrcId)
					set:$lg(tElemData,11)'="" tJSONE.output = $lg(tElemData,11)
					set tJSONE.role = $case($lg(tElemData,5),$$$ENTTYPECONCEPT:"concept",$$$ENTTYPERELATION:"relation",$$$ENTTYPENONREL:"nonRelevant",$$$ENTTYPEPATHREL:"pathRelevant")
					do tJSON.elements.%Push(tJSONE)
				}
				$$$IKRESTSTOPTIMER(details)
			}
			
			if (tIncludeSnippets) {
				$$$IKRESTSTARTTIMER(snippets)
				if $d(tHighlight) {
					set tJSON.sentence = ##class(%iKnow.Queries.SentenceAPI).GetHighlighted(pDomainId, tJSON.sentenceId, .tHighlight, vSrcId)
				} else {
					set tJSON.sentence = ##class(%iKnow.Queries.SentenceAPI).GetValue(pDomainId, tJSON.sentenceId,, vSrcId)
				}
				$$$IKRESTSTOPTIMER(snippets)
			}
		}
		
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit ..%ProcessResult(tSC, $g(tResult))
}

/// <example language="swagger">
///       summary: |
///         Retrieves all dictionary matches for a dictionary item
///       tags: ["Dictionaries and Matching"]
///       parameters:
///         - $ref: '#/parameters/domainParam'
///         - name: id
///           description: the dictionary item ID or URI to query for
///           in: path
///           required: true
///           type: integer
///       responses:
///         200:
///           description: Successful response
///           schema:
///             $ref: '#/definitions/MatchList'
/// </example>
ClassMethod GetMatchesByItemGET(namespace As %String, pDomainId As %Integer, pDictionaryItemId As %Integer) As %Status [ Internal ]
{
	quit ..GetMatchesByItem(namespace, pDomainId, pDictionaryItemId)
}

/// <example language="swagger">
///       summary: |
///         Retrieves all dictionary matches for a dictionary item
///       tags: ["Dictionaries and Matching"]
///       parameters:
///         - $ref: '#/parameters/domainParam'
///         - name: id
///           description: the dictionary item ID or URI to query for
///           in: path
///           required: true
///           type: integer
///         - name: RequestBody
///           description: JSON object with a list of query-specific arguments
///           in: body
///           schema:
///             type: object
///             properties:
///               page:
///                 $ref: '#/definitions/PageNumber'
///               pageSize:
///                 $ref: '#/definitions/PageSize'
///               filter:
///                 $ref: '#/definitions/Filter'
///                 description: optionally filters the results to those matches in sources selected by this filter
///               matchFirst:
///                 description: ensures the domain is matched against the latest dictionaries before retrieving results
///                 type: boolean
///                 format: integer
///                 default: 1
///               includeDictionaryDetails:
///                 description: whether or not to dictionary details as well
///                 type: boolean
///                 format: integer
///                 default: 1
///               includeMatchDetails:
///                 description: whether or not to entity-level match details as well
///                 type: boolean
///                 format: integer
///                 default: 0
///               includeSnippets:
///                 description: whether or not to include the text of the matched sentence
///                 type: boolean
///                 format: integer
///                 default: 1
///               highlight:
///                 $ref: '#/definitions/Highlighting'
/// 
///       responses:
///         200:
///           description: Successful response
///           schema:
///             $ref: '#/definitions/MatchList'
/// </example>
ClassMethod GetMatchesByItem(namespace As %String, pDomainId As %Integer, pDictionaryItemId As %Integer) As %Status
{
	set tSC = $$$OK
	$$$IKRESTINITDEBUG
	try {
		do ..ResolveDomainId(.pDomainId)
		set tMatchFirst = $s(%request.Content.%IsDefined("matchFirst"):%request.Content.matchFirst, 1:1)
		set tIncludeDictDetails = $s(%request.Content.%IsDefined("includeDictionaryDetails"):%request.Content.includeDictionaryDetails, 1:1)
		set tIncludeMatchDetails = $s(%request.Content.%IsDefined("includeMatchDetails"):%request.Content.includeMatchDetails, 1:0)
		set tIncludeSnippets = $s(%request.Content.%IsDefined("includeSnippets"):%request.Content.includeSnippets, 1:1)
		
		set tSC = ..ParseArgs(pDomainId, .tPage, .tPageSize, .tFilter)
		quit:$$$ISERR(tSC)
		set:tIncludeSnippets tSC = ..ParseHighlight(.tHighlight)
		quit:$$$ISERR(tSC)
		
		// accept URIs too
		if '$isvalidnum(pDictionaryItemId) {
			set tItemId = ##class(%iKnow.Matching.DictionaryAPI).GetDictionaryItemIdByURI(pDomainId,pDictionaryItemId, .tSC)
			quit:tItemId<=0
			set pDictionaryItemId = tItemId
		}
		
		set tResult = { "matches": [], "item": { "id": (pDictionaryItemId) } }
		
		// BDB734
		set tCrossDomainDict = (pDictionaryItemId < 0)
		set tDictDomainId = $s(tCrossDomainDict:0, 1:pDomainId)
		
		set tItemObj = ##class(%iKnow.Objects.DictionaryItem).PKINDEXOpen(tDictDomainId, $zabs(pDictionaryItemId))
		if '$isobject(tItemObj) {
			set tSC = $$$ERROR($$$IKDictItemDoesNotExist, pDictionaryItemId)
			quit
		}
		if (tIncludeDictDetails) {
			set tResult.item.name = tItemObj.Name, tResult.item.uri = tItemObj.URI
			set tResult.item.dictionary = { "id": (tItemObj.DictionaryId), "name": (tItemObj.Dictionary.Name) }
		}
		
		if (tMatchFirst) {
			$$$IKRESTSTARTTIMER(matching)
			set tSC = ##class(%iKnow.Matching.MatchingAPI).MatchSources(pDomainId, tFilter, $lb(tItemObj.DictionaryId * $s(tCrossDomainDict:-1, 1:1)))
			quit:$$$ISERR(tSC)
			$$$IKRESTSTOPTIMER(matching)
		}
		
		set tSC = ##class(%iKnow.Matching.MatchingAPI).GetMatchesByDictionaryItemId(.tMatches, pDomainId, pDictionaryItemId, tPage, tPageSize, tFilter)
		quit:$$$ISERR(tSC)
		set i = ""
		for {
			set i = $order(tMatches(i), 1, tMatchData)
			quit:i=""
			
			set tJSON = { "id": (+$lg(tMatchData,1)), "sourceId": (+$lg(tMatchData,3)), "score": (+$normalize($lg(tMatchData,9),4)), "partialCount": (+$lg(tMatchData,12)), "ordered":(+$lg(tMatchData,15)), "negatedCount": (+$lg(tMatchData,16)) }
			
			set tJSON.term = { "id": (+$lg(tMatchData,2)) }
			
			if (tIncludeDictDetails) {
				$$$IKRESTSTARTTIMER(dictDetails)
				set tTermObj = ##class(%iKnow.Objects.DictionaryTerm).PKINDEXOpen(tDictDomainId, $zabs(+$lg(tMatchData,2)))
				if (tTermObj.String["[") && (tTermObj.String[".") {
					set tSC = ##class(%iKnow.Matching.DictionaryAPI).GetTermElements(.tElems, tDictDomainId, tTermObj.DictionaryTermId)
					quit:$$$ISERR(tSC)
					set tSC = ##class(%iKnow.Matching.DictionaryAPI).GetFormatDetails(tDictDomainId, $lg(tElems(1),3), .tClass, .tParams)
					quit:$$$ISERR(tSC)
					set tJSON.term.formatClass = tClass
					set tJSON.term.formatParams = [], ptr=0
					while $listnext(tParams,ptr,tParam) { do tJSON.term.formatParams.%Push(tParam) }
				} else {
					set tJSON.term.string = tTermObj.String
				}
				$$$IKRESTSTOPTIMER(dictDetails)
			}
			
			set tJSON.sentenceId = ##class(%iKnow.Matching.MatchingAPI).GetSentenceIdForMatchTarget(pDomainId, $lg(tMatchData,5), $lg(tMatchData,6))
			set tJSON.target = { "id": (+$lg(tMatchData,6)) }
			set tJSON.target.type = $case($lg(tMatchData,5), $$$DMTARGETENTITY:"entity", $$$DMTARGETCRC:"crc", $$$DMTARGETPATH:"path", $$$DMTARGETSENT:"sentence")
			
			do tResult.matches.%Push(tJSON)
			
			if (tIncludeMatchDetails) {
				$$$IKRESTSTARTTIMER(matchDetails)
				set tSC = ##class(%iKnow.Matching.MatchingAPI).GetMatchElements(.tElems, pDomainId, tJSON.id)
				quit:$$$ISERR(tSC)
				set j="", tJSON.elements=[]
				for {
					set j = $order(tElems(j), 1, tElemData)
					quit:j=""
					set tJSONE = { "partId": (+$lg(tElemData,2)), "literal": ($lg(tElemData,4)), "score": (+$normalize($lg(tElemData,6),4)), "matchedWords": ($lg(tElemData,9)), "negated":(+$lg(tElemData,12)) }
					set:$lg(tElemData,3) tJSONE.entityId = +$lg(tElemData,3), tJSONE.entity = ##class(%iKnow.Queries.EntityAPI).GetValueInternal(pDomainId, tJSONE.entityId)
					set:$lg(tElemData,11)'="" tJSONE.output = $lg(tElemData,11)
					set tJSONE.role = $case($lg(tElemData,5),$$$ENTTYPECONCEPT:"concept",$$$ENTTYPERELATION:"relation",$$$ENTTYPENONREL:"nonRelevant",$$$ENTTYPEPATHREL:"pathRelevant")
					do tJSON.elements.%Push(tJSONE)
				}
				$$$IKRESTSTOPTIMER(matchDetails)
			}
			
			if (tIncludeSnippets) {
				$$$IKRESTSTARTTIMER(snippets)
				if $d(tHighlight) {
					set tJSON.sentence = ##class(%iKnow.Queries.SentenceAPI).GetHighlighted(pDomainId, tJSON.sentenceId, .tHighlight)
				} else {
					set tJSON.sentence = ##class(%iKnow.Queries.SentenceAPI).GetValue(pDomainId, tJSON.sentenceId)
				}
				$$$IKRESTSTOPTIMER(snippets)
			}
		}
		
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit ..%ProcessResult(tSC, $g(tResult))
}

/// Simplified version of <method>MatchAll</method> for HTTP GET requests
/// <example language="swagger">
///       summary: |
///         Matches all sources against the current dictionary contents
///       tags: ["Dictionaries and Matching"]
///       parameters:
///         - $ref: '#/parameters/domainParam'
/// 
///       responses:
///         200:
///           description: Successful response
///           schema:
///             type: object
///             properties:
///               matched:
///                 type: boolean
///                 format: integer
///                 default: 1
/// </example>
ClassMethod MatchAllGET(namespace As %String, pDomainId As %Integer) As %Status [ Internal ]
{
	quit ..MatchAll(namespace, pDomainId)
}

/// <example language="swagger">
///       summary: |
///         Matches all sources against the current dictionary contents
///       tags: ["Dictionaries and Matching"]
///       parameters:
///         - $ref: '#/parameters/domainParam'
///         - name: RequestBody
///           description: JSON object with a list of query-specific arguments
///           in: body
///           schema:
///             type: object
///             properties:
///               filter:
///                 $ref: '#/definitions/Filter'
///                 description: optionally limits the operation to those sources selected by this filter
///               dictionaries:
///                 description: if set, limits the operation to these dictionary IDs
///                 default: []
///                 type: array
///                 items:
///                   type: integer
/// 
///       responses:
///         200:
///           description: Successful response
///           schema:
///             type: object
///             properties:
///               matched:
///                 type: boolean
///                 format: integer
///                 default: 1
/// </example>
ClassMethod MatchAll(namespace As %String, pDomainId As %Integer) As %Status
{
	set tSC = $$$OK
	$$$IKRESTINITDEBUG
	try {
		do ..ResolveDomainId(.pDomainId)
		
		set tDictionaries = ..ParseList("dictionaries")
		set tSC = ..ParseArgs(pDomainId,,, .tFilter)
		quit:$$$ISERR(tSC)
		
		set tResult = { "matched" : 0 }
		set tSC = ##class(%iKnow.Matching.MatchingAPI).MatchSources(pDomainId, tFilter, tDictionaries)
		set tResult.matched = $$$ISOK(tResult)
		
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit ..%ProcessResult(tSC, $g(tResult))
}

/// <example language="swagger">
///       summary: |
///         Matches a particular source against the current dictionary contents
///       tags: ["Dictionaries and Matching"]
///       parameters:
///         - $ref: '#/parameters/domainParam'
///         - $ref: '#/parameters/sourceParam'
/// 
///       responses:
///         200:
///           description: Successful response
///           schema:
///             type: object
///             properties:
///               matched:
///                 type: boolean
///                 format: integer
///                 default: 1
/// </example>
ClassMethod MatchSourceGET(namespace As %String, pDomainId As %Integer, pSourceId As %Integer) As %Status [ Internal ]
{
	quit ..MatchSource(namespace, pDomainId, pSourceId)
}

/// <example language="swagger">
///       summary: |
///         Matches a particular source against the current dictionary contents
///       tags: ["Dictionaries and Matching"]
///       parameters:
///         - $ref: '#/parameters/domainParam'
///         - $ref: '#/parameters/sourceParam'
///         - name: RequestBody
///           description: JSON object with a list of query-specific arguments
///           in: body
///           schema:
///             type: object
///             properties:
///               dictionaries:
///                 description: if set, limits the operation to these dictionary IDs
///                 default: []
///                 type: array
///                 items:
///                   type: integer
/// 
///       responses:
///         200:
///           description: Successful response
///           schema:
///             type: object
///             properties:
///               matched:
///                 type: boolean
///                 format: integer
///                 default: 1
/// </example>
ClassMethod MatchSource(namespace As %String, pDomainId As %Integer, pSourceId As %Integer) As %Status
{
	set tSC = $$$OK
	$$$IKRESTINITDEBUG
	try {
		do ..ResolveDomainId(.pDomainId)
		
		set tDictionaries = ..ParseList("dictionaries")
		
		set tResult = { "matched" : 0 }
		set tSC = ##class(%iKnow.Matching.MatchingAPI).MatchSource(pDomainId, pSourceId, tDictionaries)
		set tResult.matched = $$$ISOK(tResult)
		
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit ..%ProcessResult(tSC, $g(tResult))
}

/// <example language="swagger">
///       summary: |
///         Search the given iFind index in the given table
///       tags: ["iFind"]
///       parameters:
///         - $ref: '#/parameters/tableParam'
///         - name: RequestBody
///           description: JSON object with a list of query-specific arguments
///           in: body
///           schema:
///             type: object
///             properties:
///               query:
///                 description: This is the only necessary parameter with no default value. The search terms to query against the iFind index.
///                 type: string
///               index:
///                 description: the iFind index would be searched against, if you don't specify it, the first found iFind index would be used .
///                 type: string
///               option:
///                 $ref: '#/definitions/OptionSpec'
///               distance:
///                 description: only valid when option is fuzzy search (when option is 3)
///                 type: string
///                 example: "3"
///               language:
///                 description: iKnow-supported language model to apply, for example "en"
///                 type: string
///               includeText:
///                 description: whether the returned columns should include the column beging indexed by 'index'
///                 type: integer
///                 default: 0
///                 enum: [0, 1] 
///               columns:
///                 description: specify the columns which also needed to be returned. For example, ["column1","column2"] 
///                 type: array
///                 example: []
///                 items:
///                   type: string
///               highlightSpec:
///                 $ref: '#/definitions/HighlightSpec'
///                 description: the parameters needed for Highlight
///               rankSpec:
///                 $ref: '#/definitions/RankSpec'
///                 description: the parameters needed for Rank
///               where:
///                 description: the valid SQL logical condition statement. For example, "column1 = ? AND column2 = ?"
///                 type: string
///       responses:
///         200:
///           description: Successful response
///           schema:
///             type: object
///             properties:
///               rows:
///                 type: array
///                 default: []
///                 items:
///                   type: object
/// </example>
ClassMethod SearchIndex(namespace As %String, table As %String) As %Status
{
	set index="",query="",option="",distance="",lang="",includeText = "",columns = "",rank="",highlightSpec = "",where = ""
	set tSC = $$$OK
	try{
		set:%request.Content.%IsDefined("index") index=%request.Content.index
		if '$g(index){
			set sql = "select Name from %Dictionary.CompiledIndex where parent = ? and TypeClass in (?,?,?)"
			set stat = ##class(%SQL.Statement).%New()
			set res = stat.%Prepare(sql)
			set res = stat.execute(table,"%iFind.Index.Analytic","%iFind.Index.Semantic","%iFind.Index.Basic")
			if (res.%SQLCODE=0) && (res.%Next()){
				set index = res.Name
			}
			else{
				set tSC = res.%SQLCODE quit
			}
		}
		set:%request.Content.%IsDefined("query") query=%request.Content.query
		set:$g(query)'="" query = "'"_query_"'"
		set:%request.Content.%IsDefined("option") option=%request.Content.option
		if $isobject(option){
			set optionObj = option
			set option = $s(optionObj.%IsDefined("mode"):optionObj.mode,1:"")
			set:optionObj.%IsDefined("distance") distance = optionObj.distance
			set:optionObj.%IsDefined("stemmer") stemmer = optionObj.stemmer
			set:optionObj.%IsDefined("arguments") stemmerArgs = optionObj.arguments
			if $g(stemmerArgs) && $isobject(stemmerArgs){
				set temp = ""
				set tIterator = stemmerArgs.%GetIterator()
				while (tIterator.%GetNext(,.tElem)) {
					set temp = temp_":"_tElem
				}
				set:$e(temp,1)=":" $e(temp,1)=""
				set stemmerArgs = temp
			}
		}
		set option = $s(("normal"=option):$$$IFSEARCHNORMAL,("stemmed"=option):$$$IFSEARCHSTEMMED,("decompounded"=option):$$$IFSEARCHDECOMPOUNDED,("fuzzy"=option):$$$IFSEARCHFUZZY,("regexp"=option):$$$IFSEARCHPATTERN,(($l(option,":")=2)&&($p(option,":",1)="fuzzy")):$$$IFSEARCHFUZZY_":"_$p(option,":",2),1:option)
		if ((option=$$$IFSEARCHSTEMMED) || (option=$$$IFSEARCHDECOMPOUNDED) || (option="")) && ($g(stemmer)'=""){
			set option = $case($g(stemmerArgs),"":stemmer,:stemmer_":"_stemmerArgs)
		}
		set:(distance="")&&%request.Content.%IsDefined("distance") distance = %request.Content.distance 
		set:(($p(option,":")=$$$IFSEARCHFUZZY) && ($l(option,":")=1) && ($g(distance)'="")) option = option_":"_distance 
		set:$g(option)'="" option = "'"_option_"'"
		set:$g(option)="" option = "'0'"
		set:%request.Content.%IsDefined("language") lang=%request.Content.lang
		set:$g(lang)'="" lang = "'"_lang_"'"
		set:%request.Content.%IsDefined("includeText") includeText=%request.Content.includeText
		;set:%request.Content.%IsDefined("columns") columns=%request.Content.columns
		set columns = ""
		set tIterator = ..ParseStringArray("columns", .columns).%GetIterator()
		if columns = ""{
			while (tIterator.%GetNext(,.tElem)) {
				set columns = columns_","_tElem
			}
			set:$e(columns,1)="," $e(columns,1)=""
		}
		
		set:%request.Content.%IsDefined("highlightSpec") highlightSpec=%request.Content.highlightSpec
		if $g(highlightSpec) && $isobject(highlightSpec)
		{
			set:highlightSpec.%IsDefined("tag") highlightTag = "'"_highlightSpec.tag_"'"
			set:highlightSpec.%IsDefined("limit") highlightLimit = highlightSpec.limit
			set highlightFieldName = "Highlighted"
			set:highlightSpec.%IsDefined("name") highlightFieldName = highlightSpec.name 
		}
		set:%request.Content.%IsDefined("rankSpec") rankSpec=%request.Content.rankSpec
		if $g(rankSpec) && $isobject(rankSpec)
		{
			set rankFieldName = "Rank"
			set:rankSpec.%IsDefined("name") rankFieldName = rankSpec.name 
		}
		set:%request.Content.%IsDefined("where") where="("_%request.Content.where_")"
	
		if (index = ""){
			set tSC = $$$ERROR("fail to find the iFind index in this table")
			quit 
		}
		if (query = ""){
			set tSC = $$$ERROR("no query terms specified")
			quit 
		}
		
		set sqlWhere = "search_index("_index_","_query
		set sqlWhere = sqlWhere_","_option
		set:$g(lang)'="" sqlWhere = sqlWhere_","_lang
		set sqlWhere = sqlWhere_")"
		set:where'="" sqlWhere = sqlWhere _" AND "_where
	
		set sqlColumns = "%ID"
		set columnNames($i(columnNames)) = "%ID" 
		if $g(includeText)=1{ 
			set sql = "select Properties from %Dictionary.IndexDefinition where %ID = ?"
			set stat = ##class(%SQL.Statement).%New()
			set res = stat.%Prepare(sql)
			set res = stat.execute(table_"||"_index)
			if (res.%SQLCODE=0) && (res.%Next()){
				set sqlColumns = sqlColumns_","_res.Properties
				// res.Properties could only be one field
				set columnNames($i(columnNames)) = res.Properties
			}
		}
		
		if $g(highlightSpec)'="" {
			set sqlColumns = sqlColumns _","_ table_"_"_index_"Highlight"_"("_"ID"_","_query_","_$g(option)_","_$g(highlightTag)_","_$g(highlightLimit)_","_$g(lang)_")"_" "_highlightFieldName
			set columnNames($i(columnNames)) = highlightFieldName
		}
		if $g(rankSpec)'="" { 
			set sqlColumns = sqlColumns _","_ table_"_"_index_"Rank"_"("_"ID"_","_query_","_$g(option)_")"_" "_rankFieldName
			set columnNames($i(columnNames)) = rankFieldName
		}
		if $g(columns)'=""{
			set sqlColumns = sqlColumns _"," _ columns
			for i=1:1:$l(columns,","){
				set columnNames($i(columnNames)) = $p(columns,",",i)
			}
		}
		
		set sqlQuery = "SELECT "_sqlColumns_" FROM "_table_" WHERE"_" %ID %FIND "_sqlWhere 
		
		set stat = ##class(%SQL.Statement).%New()
		set sql = sqlQuery
		set status = stat.%Prepare(sql)
		if '$$$ISOK(status) {
			set tSC = status quit
		}
		set res = stat.%Execute()
		if res.%SQLCODE '= 0 set tSC = res.%SQLCODE quit
		
		set arr = []
		while res.%Next()
		{
			set data = ""
			set row = {}
			for i=1:1:columnNames{
				set row = row.%Set(columnNames(i),res.%GetData(i))
			}
			set arr = arr.%Push(row)
		}	
		
		set ret = {}
		do ret.%Set("rows",arr)
	}
	catch(ex){
		set tSC =ex.AsStatus()
	}
	quit ..%ProcessResult(tSC, $g(ret))
}

/// Parse a few common arguments out of %request.Content
/// BDB879 - override base version to support deprecated param names
ClassMethod ParseArgs(pDomainId As %Integer = 0, Output pPage As %Integer, Output pPageSize As %Integer, Output pFilter As %iKnow.Filters.Filter, Output pFilterMode As %Integer, Output pBlacklists As %List) As %Status [ Internal ]
{
	set tSC = $$$OK
	try {
		if ('%request.Content.%IsDefined("page")) && ('%request.Content.%IsDefined("pageSize")) {
			set pPage = 1, pPageSize = ..#PAGESIZE
		} else {
			set pPage = %request.Content.page, pPageSize = %request.Content.pageSize
		}
		
		if '%request.Content.%IsDefined("filter") {
			set pFilter=""
		} elseif '$isobject(%request.Content.filter) {
			set tSC = ##class(%iKnow.Filters.Filter).FromString(pDomainId, %request.Content.filter, .pFilter)
			quit:$$$ISERR(tSC)
		} else {
			set tSC = ..ParseFilter(pDomainId, %request.Content.filter, .pFilter)
			quit:$$$ISERR(tSC)
		}
		
		if '%request.Content.%IsDefined("filterMode") {
			set pFilterMode = $$$FILTERALLANDSORT
		} else {
			set pFilterMode = +%request.Content.filterMode
		}
		
		set pBlacklists = ""
		if %request.Content.%IsDefined("blacklists") {
			set tSpec = %request.Content.blacklists
			if '$isobject(tSpec) && ($e(tSpec,1,6)="SELECT") {
				set pBlacklists = tSpec
			} else {
				set:'$isobject(tSpec) tSpec = [ (tSpec) ]
				set tIterator = tSpec.%GetIterator()
				while tIterator.%GetNext(,.tValue) {
					if $isvalidnum(tValue) {
						set pBlacklists = pBlacklists_$lb(+tValue)
					} else {
						// accept names too
						set pBlacklists = pBlacklists_$lb(##class(%iKnow.Utils.MaintenanceAPI).GetBlackListId(pDomainId, tValue))
					}
				}
			}
		}
		
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit tSC
}

}
