<cfcomponent displayname="i18nSort" hint="sorts string arrays/queries using locale based collation version 1.2 icu4j may-2006" output="no">
<!--- 
authors:	hiroshi okugawa <hokugawa@macromedia.com>
			paul hastings <paul@sustainableGIS.com>
date:		8-feb-2004
revisions:	9-feb-2004 swapped sort to use java.util.Arrays.sort() after some code i found on christian 
			cantrell's blog
			31-may-2004 added lsSortQuery and icu4jSortQuery to handle single column query sorting
			2-jun-2004 hiroshi fixed query sort, wasn't swapping keys
			10-jan-2005 fixed locale bug found by s. isaac dealey
			28-mar-2006 this version swapped to icu4j based methods
			
notes:	this cfc contains methods to handle sorting string arrays using locale based collation. you 
			should use this CFC if your application requires "non-lexigraphical" sorting (the standard CF 
			listSort and arraySort use lexigraphical sorting and basically compare string lengths and 
			unicode code points, which will return incorrect sorting in some instances, for example german 
			umluats Ä,Ë,Ü will sort to the end of any list/array, contrary to what users in DE locale 
			expect).
			
			these sort methods are based on IBM's ICU4J java lib which provides much heftier 
			sorting than core java, it has almost double the number of collate locales available (134 vs 246 for icu4j
			including phonebook collations). it requires that the ICU4J lib be installed. you can download
			ICU4J lib from: 
			
			http://oss.software.ibm.com/icu4j/ 
			
			extract the .JAR file and place it in cfusionMX/wwwroot.web-inf/lib
			
methods in this CFC:
	- lsSort returns array sorted on given collate locale. required argument is toSort, array of strings
	or numerics to sort. this sort is based on icu4j lib com.ibm.icu.text.Collator class. other 
	non-required arguments:
		-- sortDir direction to sort array on, Asc (ascending) or Desc (descending). default is Asc
		-- thisLocale java style locale (en_US, th_TH, etc.) to base collation on. defaults to en_US
		-- thisStrength collator strength value, sets level of comparison difference, valid values are
			IDENTICAL, PRIMARY, SECONDARY, QUATERNARY and the default of TERTIARY. the exact assignment 
			of strengths varies locale to locale
		-- thisDecomposition determines how strings are decomposed in comparison. valid values:
			--- NO_DECOMPOSITION ignores accents, etc. fastest sort but wrong in many locales
			--- CANONICAL_DECOMPOSITION includes accents and chars with special formats, most complete but
				slowest, default.
	- lsSortQuery returns query sorted on given collate locale. required arguments are toSort, query 
	to sort, sortColumn column in toSort to use in collation. this sort is based on icu4j lib 
	com.ibm.icu.text.Collator class. other non-required arguments:
		-- sortDir direction to sort query on, Asc (ascending) or Desc (descending). default is Asc
		-- retainSortID boolean indicating whether to return generated collate sort ID, default is false		
		-- thisLocale java style locale (en_US, th_TH, etc.) to base collation on. defaults to en_US
		-- thisStrength collator strength value, sets level of comparison difference, valid values are
			IDENTICAL, PRIMARY, SECONDARY, QUATERNARY and the default of TERTIARY. the exact assignment 
			of strengths varies locale to locale
		-- thisDecomposition determines how strings are decomposed in comparison. valid values:
			--- NO_DECOMPOSITION ignores accents, etc. fastest sort but wrong in many locales
			--- CANONICAL_DECOMPOSITION includes accents and chars with special formats, most complete but
				slowest, default.				
	- getCollateLocaleNames returns array holding display names (Greek (Greece)) for available collate 
	locales. based on icu4j lib com.ibm.icu.text.Collator class. with icu4j ver 2.8 provides 246 locales,
	compared to 134 with jre 1.4.2. includes german phonebook, persian (farsi), etc. this is where icu4j
	outshines the normal java i18n classes.
	- getCollateLocales returns array holding java style locales (en_US) for available collate 
	locales. based on icu4j lib com.ibm.icu.text.Collator class. with icu4j ver 2.8 provides 246 locales,
	compared to 134 with jre 1.4.2. includes german phonebook, persian (farsi), etc.  this is where icu4j
	outshines the normal java i18n classes.

--->

<cffunction access="public" name="init" output="No" hint="initializes needed classes">
<cfargument name="icu4jJarFile" required="no" type="string" default="c:\JRun4\servers\cfusion\cfusion-ear\cfusion-war\WEB-INF\lib\icu4j.jar">
<cfscript>
	var paths=listToArray(arguments.icu4jJarFile);
	var loader=createObject("component", "JavaLoader").init(paths);
	variables.aLocale=loader.create("com.ibm.icu.util.ULocale");
	variables.icu4jCollator=loader.create("com.ibm.icu.text.Collator");
	variables.aVersionInfo=loader.create("com.ibm.icu.util.VersionInfo");
	variables.I18NSortVersion="1.2 icu4j";
	variables.I18NSortDate="may-2006"; //should be date of latest change	
	return this;
</cfscript>
</cffunction>

<!--- /////////////////////////// lsSort /////////////////////////////////////////// --->
<cffunction name="lsSort" output="No" returntype="array" hint="returns array sorted using ICU4J collator">
<cfargument name="toSort" type="array" required="yes">
<cfargument name="sortDir" type="string" required="no" default="Asc">
<cfargument name="thisLocale" type="string" required="no" default="en_US">
<cfargument name="thisStrength" type="string" required="no" default="TERTIARY">
<cfargument name="thisDecomposition" type="string" required="no" default="FULL_DECOMPOSITION">
<cfscript>
var tmp="";
var i=0;
var strength="";
var decomposition="";
var locale=getICU4JLocale(arguments.thisLocale);
var thisCollator=getICU4JCollator(locale);
//set up the collation options
//strength of comparison
strength=thisCollator.TERTIARY; //includes case differences, 'A' vs 'a'
switch (arguments.thisStrength){
	case "PRIMARY" :
		strength=thisCollator.PRIMARY; //handles base letters 'a' vs 'b'
	break;
	case "SECONDARY" : 
		strength=thisCollator.SECONDARY; //handles accented chars
	break;
	case "QUATERNARY" :
		strength=thisCollator.QUATERNARY; //handles accented chars, ignores punctuation
	break;
	case "IDENTICAL" :
		strength=thisCollator.IDENTICAL; //all differences, including control chars are considered
	break;		
}
//decompositions, only 2 for icu4j
//compromise, handles accented chars but not special forms
decomposition=thisCollator.CANONICAL_DECOMPOSITION;
//fastest sort but won't handle accented chars, etc.
if (arguments.thisDecomposition EQ "NO_DECOMPOSITION")
	decomposition=thisCollator.NO_DECOMPOSITION;
thisCollator.setStrength(strength); //strength
thisCollator.setDecomposition(decomposition);  //decomposition
tmp=arguments.toSort.toArray();
Arrays.sort(tmp,thisCollator);  //do the array sort based on this collator
if (arguments.sortDir EQ "Desc") { //need to swap array?
	arguments.toSort=arrayNew(1);
	for (i=arrayLen(tmp);i GTE 1; i=i-1) {
		arrayAppend(arguments.toSort,tmp[i]);
	} 
} else arguments.toSort=tmp;
return arguments.toSort;
</cfscript>
</cffunction>

<!--- /////////////////////////// lsSortQuery /////////////////////////////////////////// --->
<cffunction name="lsSortQuery" output="no" returntype="query" hint="sorts query based on ICU4J collator">
<cfargument name="toSort" type="query" required="yes" >
<cfargument name="sortColumn" type="string" required="yes">
<cfargument name="sortDir" type="string" required="no" default="Asc">
<cfargument name="retainSortID" type="boolean" required="no" default="false">
<cfargument name="thisLocale" type="string" required="no" default="en_US">
<cfargument name="thisStrength" type="string" required="no" default="TERTIARY">
<cfargument name="thisDecomposition" type="string" required="no" default="FULL_DECOMPOSITION">
<cfscript>
var tmp="";
var tmpQ=duplicate(arguments.toSort); //let's not mess with passed query
var i=0;
var j=0;
var sorted="";
var strength="";
var decomposition="";
var sortIDs=arrayNew(1);
var collateKeys=arrayNew(2); // hold generated collate keys
var colList=tmpQ.columnList; // original query column list
var keys=arrayNew(1); // holds strings pulled from sortColumn
var locale=getICU4JLocale(arguments.thisLocale);
var thisCollator=getICU4JCollator(locale);
// prep query
for (i=1;i LTE tmpQ.recordCount;i=i+1) {
	arrayAppend(sortIDs,i);
	arrayAppend(keys,javacast("string",tmpQ[arguments.sortColumn][i]));
}
queryAddColumn(tmpQ,"collateSortID",sortIDs);
//set up the collation options
//strength of comparison
strength=thisCollator.TERTIARY; //includes case differences, 'A' vs 'a'
switch (arguments.thisStrength){
	case "PRIMARY" :
		strength=thisCollator.PRIMARY; //handles base letters 'a' vs 'b'
	break;
	case "SECONDARY" : 
		strength=thisCollator.SECONDARY; //handles accented chars
	break;
	case "QUATERNARY" :
		strength=thisCollator.QUATERNARY; //handles accented chars, ignores punctuation
	break;
	case "IDENTICAL" :
		strength=thisCollator.IDENTICAL; //all differences, including control chars are considered
	break;		
}
//decompositions, only 2 for icu4j
//compromise, handles accented chars but not special forms
decomposition=thisCollator.CANONICAL_DECOMPOSITION;
//fastest sort but won't handle accented chars, etc.
if (arguments.thisDecomposition EQ "NO_DECOMPOSITION") 
	decomposition=thisCollator.NO_DECOMPOSITION;
//init collator
thisCollator.setStrength(strength); //strength
thisCollator.setDecomposition(decomposition);  //decomposition
// build up collationKeys
arrayset(collateKeys[1], 1, tmpQ.recordCount, "");
for (i=1; i LTE arraylen(keys); i=i+1) {
	collateKeys[1][i]=thisCollator.getCollationKey(keys[i]);
	collateKeys[2][i]=i;
}
//sort query
for (i=1; i LTE arrayLen(collateKeys[1]); i=i+1) {
	for (j=i+1; j LTE arrayLen(collateKeys[1]); j=j+1) {
		if (collateKeys[1][i].compareTo(collateKeys[1][j]) GT 0) {
			ArraySwap(collateKeys[1], i, j);
			ArraySwap(collateKeys[2], i, j);
		}
	}
	tmpQ.collateSortID[collateKeys[2][i]]=i;
}
</cfscript>
<!--- use QofQ to do final sort --->
<cfif arguments.retainSortID> <!--- keep collateSortID? --->
	<cfquery name="sorted" dbtype="query">
		SELECT *
		FROM tmpQ
		ORDER BY collateSortID #arguments.sortDir#
	</cfquery>
<cfelse> <!--- nope --->
	<cfquery name="sorted" dbtype="query">
		SELECT #colList#
		FROM tmpQ
		ORDER BY collateSortID #arguments.sortDir#
	</cfquery>
</cfif> <!--- keep collateSortID? --->
<cfreturn sorted>
</cffunction>

<!--- /////////////////////////// getCollateLocaleNames /////////////////////////////////////////// --->
<cffunction name="getCollateLocaleNames" output="No" returntype="array">
<cfscript>
var theseCollateLocales=arrayNew(1);
var collateLocales=createObject("Java","com.ibm.icu.text.Collator").getAvailableULocales();
for (i=1;i LTE arrayLen(collateLocales);i=i+1) {
	arrayAppend(theseCollateLocales,collateLocales[i].getDisplayName());
}
return theseCollateLocales;
</cfscript>
</cffunction>

<!--- /////////////////////////// getCollateLocales /////////////////////////////////////////// --->
<cffunction name="getCollateLocales" output="No" returntype="array">
<cfscript>
var theseCollateLocales=arrayNew(1);
var collateLocales=variables.icu4jCollator.getAvailableULocales();
for (i=1;i LTE arrayLen(collateLocales);i=i+1) {
	arrayAppend(theseCollateLocales,collateLocales[i].toString());
}
return theseCollateLocales;
</cfscript>
</cffunction>

<cffunction name="getICU4JLocale" access="private" output="no" hint="returns a ULocale">
	<cfargument name="locale" required="yes" type="string">
	<cfscript>
	var objArray=listToArray(arguments.locale).toArray();
	return variables.uLocale.newInstance(objArray);
	</cfscript>
</cffunction>

<cffunction name="getICU4JCollator" access="private" output="no" hint="returns a Collator class">
	<cfargument name="uLocale" required="yes">
	<cfscript>
	var objArray=listToArray(arguments.uLocale).toArray();
	return variables.icu4jCollator.newInstance(objArray);
	</cfscript>
</cffunction>

<cffunction access="public" name="getVersion" output="false" returntype="struct" hint=" returns version of this CFC and icu4j library it uses.">
<cfscript>
	var version=StructNew();
	version.I18NSortVersion=I18NSortVersion;
	version.I18NSortDate=I18NSortDate;
	version.icu4jVersion=aVersionInfo.ICU_VERSION.toString();
	version.icu4jCollation=aVersionInfo.UCOL_BUILDER_VERSION.toString();
	version.icu4jRuntime=aVersionInfo.UCOL_RUNTIME_VERSION.toString();	
	return version;
</cfscript>
</cffunction>

<!--- remove for production? --->
<cffunction name="dumpMe" access="public" returntype="any" output="No">
	<cfset var tmpStr="">
	<cfsavecontent variable="tmpStr">
		<cfdump var="#variables#"/>
	</cfsavecontent>
	<cfreturn tmpStr>
</cffunction>

</cfcomponent>
