<cfcomponent displayname="I18NUtil" hint="util I18N functions: version 1.22 icu4j 30-may-2006 Paul Hastings (paul@sustainbleGIS.com)" output="false">
<!--- 

author:		paul hastings <paul@sustainableGIS.com>
date:		1-April-2004
revisions:	25-jun-2004 added locale number formating
			7-jul-2004	added localized digit parsing
			11-jul-2004	added to/from Arabic-Indic digit functions
			12-jul-2004 added metadata function, getDecimalSymbols
			13-jul-2004 added localized country and language display functions, showLocaleCountry & showLocaleLanguage
			16-jul-2004 added method to return namepart for filtering/sorting on per locale basis
			16-aug-2004	added method to delete unicode named files/dirs
			3-feb-2005 swapped to ulocales
			20-feb-2005 added getCurrencySymbol method
			9-jul-2005 added i18nBigDecimalFormat
			30-may-2006 swapped to using java epoch offsets from datetimes
notes:
this CFC contains a several util I18N functions. all valid java locales	are supported. it requires the use 
of cfobject. 

methods in this CFC:
	
	- getLocales returns LIST of java style locales (en_US,etc.) available on this server. PUBLIC
	- getLocaleNames returns LIST of java style locale names available on this server. PUBLIC
	- isBIDI returns boolean indicating whether given locale uses lrt to rtl writing sysem direction. 
	required argument is thisLocale. PUBLIC
	- isValidLocale returns BOOLEAN indicating whether a given locale is valid on this server. should
	be used for locale validation prior to passing to this CFC. takes one required argument, thisLocale,
	string such as "en_US", "th_TH", etc. PUBLIC
	- showCountry: returns country display name in english from given locale, takes 
	one required argument, thisLocale. returns string. PUBLIC
	- showLanguage: returns language display name in english from given locale, takes 
	one required argument, thisLocale. returns string. PUBLIC
	- showLocaleCountry: returns localized country display name from given locale, takes 
	one required argument, thisLocale. returns string. PUBLIC
	- showLocaleLanguage: returns localized language display name from given locale, takes 
	one required argument, thisLocale. returns string. PUBLIC	
	- i18nIntegerFormat returns integer formatted for given locale. required arguments are thisLocale,
	valid java style locale, thisNumber integer to be formatted. optional argument useGrouping, boolean,
	determines whether grouping is used, eg. 1,000 vs 1000. PUBLIC
	- i18nDecimalFormat returns decimal formatted for given locale. required arguments are thisLocale,
	valid java style locale, thisNumber decimal to be formatted. PUBLIC
	- i18nBigDecimalFormat returns big decimal formatted for given locale. required arguments are thisLocale,
	valid java style locale, thisNumber big decimal to be formatted. optional argument is 
	decimal places, number of fraction digits to format, defaults to 3. PUBLIC	
	- i18nCurrencyFormat returns currency formatted for given locale. required arguments are thisLocale,
	valid java style locale, thisNumber currency amount to be formatted. PUBLIC
	- i18nPercentFormat returns percentage formatted for given locale. required arguments are thisLocale,
	valid java style locale, thisNumber fractional number to be formatted as percentage. PUBLIC
	- i18nParseNumber parses localized number string to numeric object, required arguments are thisLocale,
	valid java style locale, thisNumber string for formatted localized numerics. PUBLIC
	- getVersion returns version of this CFC and icu4j library it uses. PUBLIC
	- toArabicDigits simple replace of European digits[0-9]	with Arabic-Indic digits. required
	argument is thisNumber, string of European digits. note that no formatting takes place. PUBLIC
	- fromArabicDigits simple replace of Arabic-Indic digits with European digits. required
	argument is thisNumber, string of European digits. note that no formatting takes place. PUBLIC	
	- getDecimalSymbols METADATA function, returns structure holding various decimal format symbols for
	given locale. required argument is thisLocale, valid java style locale. PUBLIC
	- getCurrencySymbol METADATA function, returns international (USD, THB,
	etc.) or localized  currency symbol for given locale. required argument is thisLocale, 
	valid java style locale. optional boolean argument is localized to return localized or
	international currency symbol. defaults to true (localized). PUBLIC
	- getLocaleNameFilter returns name part (firstname,lasname) used in filtering/sorting names on a per 
	locale basis. required argument is thisLocale, valid java style locale. note that these are manually supplied rules. PUBLIC
 --->
 
<cffunction access="public" name="init" output="No" hint="initializes needed classes">
<cfargument name="icu4jJarFile" required="no" type="string" default="c:\JRun4\servers\cfusion\cfusion-ear\cfusion-war\WEB-INF\lib\icu4j.jar">
<cfscript>
	var paths=listToArray(arguments.icu4jJarFile);
	var loader=createObject("component", "JavaLoader").init(paths);
	variables.aCalendar=loader.create("com.ibm.icu.util.Calendar");
	variables.aDFSymbol=loader.create("com.ibm.icu.text.DecimalFormatSymbols");
	variables.aNumberFormat=loader.create("com.ibm.icu.text.NumberFormat");
	variables.aDateFormat=loader.create("com.ibm.icu.text.DateFormat");
	variables.arabicShaping=loader.create("com.ibm.icu.text.ArabicShaping"); // we have other uses coming
	variables.aLocale=loader.create("com.ibm.icu.util.ULocale");
	variables.timeZone=loader.create("com.ibm.icu.util.TimeZone");
	variables.aLocaleData=loader.create("com.ibm.icu.util.LocaleData");
	variables.aBigDecimal=loader.create("com.ibm.icu.math.BigDecimal");
	variables.rulebasedFormatter=loader.create("com.ibm.icu.text.RuleBasedNumberFormat");
	variables.aVersionInfo=loader.create("com.ibm.icu.util.VersionInfo");
	variables.I18NUtilVersion="1.22 icu4j";
	variables.I18NUtilDate="30-may-2006"; //should be date of latest change	
	return this;
</cfscript>
</cffunction>

<cffunction access="public" name="getISOlanguages" output="false" returntype="array" hint="returns array of 2 letter ISO languages">
	<cfreturn aLocale.getISOLanguages()>
</cffunction> 

<cffunction access="public" name="getISOcountries" output="false" returntype="array" hint="returns array of 2 letter ISO countries">
	<cfreturn aLocale.getISOCountries()>
</cffunction> 

<cffunction access="public" name="getLocales" output="false" returntype="array" hint="returns array of locales">
	<cfreturn aLocale.getAvailableLocales()>
</cffunction> 

<cffunction access="public" name="acceptLanguage" output="false" hint="returns best available ulocale from HTTP_ACCEPT_LANGUAGE in a structure holding locale & if the locale is a fallback" returntype="struct">
<cfargument name="acceptLanguageList" required="yes" type="string" hint="value of CGI.HTTP_ACCEPT_LANGUAGE">
<cfargument name="acceptableLocalesList" required="yes" type="string" hint="list of acceptable locales">
<cfscript>
	var acceptableLocales=listToArray(arguments.acceptableLocalesList);
	var i=0;
	var locales=arrayNew(1);
	var fallback=arrayNew(1);
	var results=structNew();
	fallback[1]=false;
	for (i=1; i LTE arrayLen(acceptableLocales); i=i+1) {
		arrayAppend(locales,aLocale.init(acceptableLocales[i]));
	}
	try {
		results.locale=aLocale.acceptLanguage(arguments.acceptLanguageList,locales,fallback);
		results.fallback=fallback[1];
	}	
	catch (Any e) {
		results.locale="";
		results.fallack=false;
	}
	return results;
</cfscript>	
</cffunction> 

<cffunction access="public" name="getLocaleNames" output="false" returntype="string" hint="returns list of locale names, UNICODE direction char (LRE/RLE) added as required">
<cfscript>
	var orgLocales="";
	var theseLocales="";	
	var thisName="";
	var i=0;
	orgLocales = getLocales();
	for (i=1; i LTE arrayLen(orgLocales); i=i+1) {
		if (listLen(orgLocales[i],"_") EQ 2) {
			if (left(orgLocales[i],2) EQ "ar" or left(orgLocales[i],2) EQ "iw")
				thisName=chr(8235)&orgLocales[i].getDisplayName(orgLocales[i])&chr(8234);
			else 
				thisName=orgLocales[i].getDisplayName(orgLocales[i]);
			theseLocales=listAppend(theseLocales,thisName);
		} // if locale more than language
	} //for
	return theseLocales;	
</cfscript>
</cffunction> 

<cffunction access="public" name="showCountry" output="false" returntype="string" hint="returns display country name for given locale">
<cfargument name="thisLocale" required="yes" type="string">	
	<cfset var locale=aLocale.init(arguments.thisLocale)>	
	<cfreturn locale.getDisplayCountry()>	
</cffunction> 

<cffunction access="public" name="showISOCountry" output="false" returntype="string" hint="returns 2-letter ISO country name for given locale">
<cfargument name="thisLocale" required="yes" type="string">	
	<cfset var locale=aLocale.init(arguments.thisLocale)>	
	<cfreturn locale.getCountry()>	
</cffunction> 

<cffunction access="public" name="showLanguage" output="false" returntype="string" hint="returns display country name for given locale">
<cfargument name="thisLocale" required="yes" type="string">	
	<cfset var locale=aLocale.init(arguments.thisLocale)>	
	<cfreturn locale.getDisplayLanguage()>	
</cffunction>

<cffunction access="public" name="showLocaleCountry" output="false" returntype="string" hint="returns display country name for given locale">
<cfargument name="thisLocale" required="yes" type="string">	
	<cfset var locale=aLocale.init(arguments.thisLocale)>	
	<cfreturn locale.getDisplayCountry(locale)>	
</cffunction> 

<cffunction access="public" name="showLocaleLanguage" output="false" returntype="string" hint="returns display country name for given locale">
<cfargument name="thisLocale" required="yes" type="string">	
	<cfset var locale=aLocale.init(arguments.thisLocale)>	
	<cfreturn locale.getDisplayLanguage(locale)>	
</cffunction>

<cffunction access="public" name="isValidLocale" output="false" returntype="boolean">
<cfargument name="thisLocale" required="yes" type="string">
	<cfset var isOK=false>
	<cfif listFind(arrayToList(getLocales()),arguments.thisLocale)>
		<cfset isOK=true>
	</cfif>
	<cfreturn isOK>
</cffunction> 

<cffunction access="public" name="isBidi" output="No" returntype="boolean" hint="determines if given locale is BIDI">
<cfargument name="thisLocale" required="yes" type="string">
	<cfif listFind("ar,he,fa,ps",left(arguments.thisLocale,2))>
		<cfreturn true>
	<cfelse>
		<cfreturn false>
</cfif>		
</cffunction>

<cffunction access="public" name="i18nIntegerFormat" output="false" returntype="string" hint="formats integer for given locale">
<cfargument name="thisNumber" required="yes" type="numeric">
<cfargument name="thisLocale" required="yes" type="string">
	<cfset var locale=aLocale.init(arguments.thisLocale)>
	<cfset var intNF=aNumberFormat.getIntegerInstance(locale)>
	<cfset var bigInt=aBigDecimal.init(thisNumber)>
	<cfreturn intNF.format(bigInt)>	
</cffunction>

<cffunction access="public" name="i18nDecimalFormat" output="false" returntype="string" hint="formats decimal for given locale">
<cfargument name="thisNumber" required="yes" type="numeric">
<cfargument name="thisLocale" required="yes" type="string">
<cfargument name="decimalPlaces" required="no" type="numeric" default="3">
	<cfset var locale=aLocale.init(arguments.thisLocale)>
	<cfset var decimalNF=aNumberFormat.getInstance(locale)>
	<cfset var bigDecimal=aBigDecimal.init(thisNumber)>
	<cfset decimalNF.setMaximumFractionDigits(arguments.decimalPlaces)>
	<cfreturn decimalNF.format(bigDecimal)>	
</cffunction>

<cffunction access="public" name="i18nBigDecimalFormat" output="false" returntype="string" hint="formats decimal for given locale">
<cfargument name="thisNumber" required="yes" type="numeric">
<cfargument name="thisLocale" required="yes" type="string">
<cfargument name="decimalPlaces" required="no" type="numeric" default="3">
	<cfset var locale=aLocale.init(arguments.thisLocale)>
	<cfset var bigDecimalNF=aNumberFormat.getInstance(locale)>
	<cfset var bigDecimal=aBigDecimal.init(thisNumber)>
	<cfset bigDecimalNF.setMaximumFractionDigits(arguments.decimalPlaces)>
	<cfreturn bigDecimalNF.format(bigDecimal)>	
</cffunction>

<cffunction access="public" name="i18nCurrencyFormat" output="false" returntype="string" hint="formats currency amount for given locale">
<cfargument name="thisNumber" required="yes" type="numeric">
<cfargument name="thisLocale" required="yes" type="string">
	<cfset var locale=aLocale.init(arguments.thisLocale)>
	<cfset var currencyNF=aNumberFormat.getCurrencyInstance(locale)>
	<cfset var bigDecimal=aBigDecimal.init(thisNumber)>
	<cfreturn currencyNF.format(bigDecimal)>
</cffunction>

<cffunction access="public" name="i18nPercentFormat" output="false" returntype="string" hint="formats fractional number as percentage for given locale">
<cfargument name="thisNumber" required="yes" type="numeric">
<cfargument name="thisLocale" required="yes" type="string">
<cfargument name="decimalPlaces" required="no" type="numeric" default="2">
	<cfset var locale=aLocale.init(arguments.thisLocale)>	
	<cfset var percentNF=aNumberFormat.getPercentInstance(locale)>
	<cfset var bigDecimal=aBigDecimal.init(thisNumber)>
	<cfset percentNF.setMaximumFractionDigits(javacast("int",arguments.decimalPlaces))>	
	<cfreturn percentNF.format(bigDecimal)>
</cffunction>

<cffunction access="public" name="i18nRuleBasedFormat" output="false" returntype="string" hint="formats number as spellout, ordinal, duration for given locale">
<cfargument name="thisNumber" required="yes" type="numeric">
<cfargument name="thisLocale" required="yes" type="string">
<cfargument name="formatType" required="no" type="numeric" default="1" hint="which type of formatting to cary out: 1=spellout (default), 2=ordinal, 3=duration">
	<cfset var locale=aLocale.init(arguments.thisLocale)>	
	<cfset var rBF=rulebasedFormatter.init(locale,arguments.formatType)>
	<cfset var bigDecimal=aBigDecimal.init(arguments.thisNumber)>
	<cfreturn rBF.format(bigDecimal)>
</cffunction>

<cffunction access="public" name="i18nRuleBasedParse" output="false" returntype="string" hint="parses a spellout, ordinal or duration formatted number for given locale">
<cfargument name="thisNumberString" required="yes" type="string" hint="formatted number to parse">
<cfargument name="thisLocale" required="yes" type="string">
	<cfset var locale=aLocale.init(arguments.thisLocale)>	
	<cfset var rBF=rulebasedFormatter.init(locale,1)> <!--- any formatter should do --->
	<cfset rBF.setLenientParseMode(true)>
	<cftry>
		<cfreturn rBF.parse(arguments.thisNumberString)>
		<cfcatch type="Any">
			<cfreturn "error: unparseable string">
		</cfcatch>
	</cftry>
</cffunction>

<cffunction access="public" name="i18nParseNumber" output="false" returntype="string" hint="parses localized number string to numeric object">
<cfargument name="thisNumber" required="yes" type="string">
<cfargument name="thisLocale" required="yes" type="string">
<cfscript>
	var locale=aLocale.init(arguments.thisLocale);	
	var currencySymbol=aDFSymbol.init(locale).getCurrencySymbol();
	var percentSymbol=aDFSymbol.init(locale).getPercent();
	var numberStr=trim(replace(arguments.thisNumber,currencySymbol,"","ALL"));
	if (numberStr CONTAINS percentSymbol)
		return (aNumberFormat.getInstance(locale).parse(numberStr))/100.00;
	else	
		return aNumberFormat.getInstance(locale).parse(numberStr);
</cfscript>
</cffunction>

<cffunction access="public" name="getVersion" output="false" returntype="struct" hint=" returns version of this CFC and icu4j library it uses.">
<cfscript>
	var version=StructNew();
	version.I18NUtilVersion=I18NUtilVersion;
	version.I18NUtilDate=I18NUtilDate;
	version.icu4jVersion=aVersionInfo.ICU_VERSION.toString();
	version.icu4jCollation=aVersionInfo.UCOL_BUILDER_VERSION.toString();
	version.icu4jRuntime=aVersionInfo.UCOL_RUNTIME_VERSION.toString();	
	return version;
</cfscript>
</cffunction>

<cffunction access="public" name="toArabicDigits" output="false" returntype="string" hint="simple replace of european digits w/arabic-indic ones">
<cfargument name="thisNumber" required="yes" type="string" hint="european digits to 'shape' to arabic-indic">
	<cfreturn arabicShaping.init(arabicShaping.DIGITS_EN2AN).shape("#arguments.thisNumber#")>
</cffunction>

<cffunction access="public" name="fromArabicDigits" output="false" returntype="string" hint="simple replace of arabic-indic digits w/european ones">
<cfargument name="thisNumber" required="yes" type="string" hint="arabic-indic digits to 'shape' to european">
	<cfreturn arabicShaping.init(arabicShaping.DIGITS_AN2EN).shape("#arguments.thisNumber#")>
</cffunction>

<cffunction access="public" name="getCurrencySymbol" returntype="string" output="false" hint="returns currency symbol for this locale">
<cfargument name="thisLocale" required="yes" type="string" hint="locale to return currency format symbols for">
<cfargument name="localized" required="no" type="boolean" default="true" hint="return international (USD, THB, etc.) or localized ($,etc.) symbol">
	<cfset var locale=aLocale.init(arguments.thisLocale)>
	<cfset var aCurrency=createObject("java","com.ibm.icu.util.Currency")>
	<cfset var tmp=arrayNew(1)>
	<cfif arguments.localized>
		<cfset arrayAppend(tmp,true)>
		<cfreturn aCurrency.getInstance(locale).getName(locale,aCurrency.SYMBOL_NAME,tmp)>
	<cfelse>
		<cfreturn aCurrency.getInstance(locale).getCurrencyCode()>		
	</cfif>
</cffunction>

<cffunction access="public" name="getDecimalSymbols" output="false" returntype="struct" hint="returns strucure holding decimal format symbols for this locale">
<cfargument name="thisLocale" required="yes" type="string" hint="locale to return decimal format symbols for">
<cfscript>
	var locale=aLocale.init(arguments.thisLocale);	
	var dfSymbols=aDFSymbol.init(locale);
	var symbols=structNew();
	symbols.plusSign=dfSymbols.getPlusSign().toString();
	symbols.Percent=dfSymbols.getPercent().toString();
	symbols.minusSign=dfSymbols.getMinusSign().toString();
	symbols.currencySymbol=dfSymbols.getCurrencySymbol().toString();
	symbols.internationCurrencySymbol=dfSymbols.getInternationalCurrencySymbol().toString();
	symbols.monetaryDecimalSeparator=dfSymbols.getMonetaryDecimalSeparator().toString();
	symbols.exponentSeparator=dfSymbols.getExponentSeparator().toString();
	symbols.perMille=dfSymbols.getPerMill().toString();
	symbols.decimalSeparator=dfSymbols.getDecimalSeparator().toString();
	symbols.groupingSeparator=dfSymbols.getGroupingSeparator().toString();
	symbols.zeroDigit=dfSymbols.getZeroDigit().toString();
	return symbols;
</cfscript>
</cffunction>

<cffunction access="public" name="getLocaleNameFilter" output="false" returntype="string" hint="returns filter by firstname or lastname appropriate for this locale">
<cfargument name="thisLocale" required="yes" type="string" hint="locale to return name filter for">
	<cfswitch expression="#left(arguments.thisLocale,5)#"> <!--- ignore variants --->
		<cfcase value="th_TH"> <!--- basically put special cases here --->
		<cfreturn "firstname">
	</cfcase>
	<cfdefaultcase> <!--- en_US, etc. --->
		<cfreturn "lastname">
	</cfdefaultcase>
	</cfswitch>
</cffunction>

<cffunction access="public" name="i18nDateTimeFormat" output="No" returntype="string"> 
<cfargument name="thisOffset" required="yes" type="numeric" hint="java epoch offset">
<cfargument name="thisLocale" required="no" type="string" default="en_US">
<cfargument name="thisDateFormat" default="1" required="No" type="numeric">
<cfargument name="thisTimeFormat" default="1" required="No" type="numeric">
<cfargument name="tz" required="no" default="#variables.timeZone.getDefault().getDisplayName()#">
	<cfset var tDateFormat=javacast("int",arguments.thisDateFormat)>
	<cfset var tTimeFormat=javacast("int",arguments.thisTimeFormat)>
	<cfset var tLocale=aLocale.init(arguments.thisLocale)>	
	<cfset var tDateFormatter=aDateFormat.getDateTimeInstance(tDateFormat,tTimeFormat,tLocale)>
	<cfset var tTZ=timeZone.getTimezone(arguments.tz)>
	<cfset tDateFormatter.setTimezone(tTZ)>
	<cfreturn tDateFormatter.format(arguments.thisOffset)>
</cffunction>

<cffunction access="public" name="i18nDateFormat" output="No" returntype="string"> 
<cfargument name="thisOffset" required="yes" type="numeric" hint="java epoch offset">
<cfargument name="thisLocale" required="no" type="string" default="en_US">
<cfargument name="thisDateFormat" default="1" required="No" type="numeric">
<cfargument name="tz" required="no" default="#variables.timeZone.getDefault().getDisplayName()#">
	<cfset var tDateFormat=javacast("int",arguments.thisDateFormat)>
	<cfset var tLocale=aLocale.init(arguments.thisLocale)>	
	<cfset var tDateFormatter=aDateFormat.getDateInstance(tDateFormat,tLocale)>
	<cfset var tTZ=timeZone.getTimezone(arguments.tz)>
	<cfset tDateFormatter.setTimezone(tTZ)>	
	<cfreturn tDateFormatter.format(arguments.thisOffset)>
</cffunction>

<cffunction access="public" name="i18nTimeFormat" output="No" returntype="string"> 
<cfargument name="thisOffset" required="yes" type="numeric" hint="java epoch offset">
<cfargument name="thisLocale" required="no" type="string" default="en_US">
<cfargument name="thisTimeFormat" default="1" required="No" type="numeric">
<cfargument name="tz" required="no" default="#variables.timeZone.getDefault().getDisplayName()#">
	<cfset var tTimeFormat=javacast("int",arguments.thisTimeFormat)>
	<cfset var tLocale=aLocale.init(arguments.thisLocale)>	
	<cfset var tTimeFormatter=aDateFormat.getTimeInstance(tTimeFormat,tLocale)>
	<cfset var tTZ=timeZone.getTimezone(arguments.tz)>
	<cfset tTimeFormatter.setTimezone(tTZ)>	
	<cfreturn tTimeFormatter.format(arguments.thisOffset)>
</cffunction>

<cffunction access="public" name="i18nDateParse" output="No" returntype="numeric" hint="parses localized date string to datetime object or returns blank if it can't parse"> 
<cfargument name="thisDate" required="yes" type="string">
<cfargument name="thisLocale" required="yes" type="string">
	<cfset var isOk=false>
	<cfset var i=0>
	<cfset var parsedDate="">
	<cfset var tLocale=aLocale.init(arguments.thisLocale)>	
	<cfset var tDateFormatter="">
	<!--- holy cow batman, can't parse dates in an elegant way. bash! pow! socko! --->
	<cfloop index="i" from="0" to="3">
		<cfset isOK=true>
		<cfset tDateFormatter=aDateFormat.getDateInstance(javacast("int",i),tLocale)>
		<cftry>
			<cfset parsedDate=tDateFormatter.parse(arguments.thisDate)>
			<cfcatch type="Any">
				<cfset isOK=false>
			</cfcatch>
		</cftry>
		<cfif isOK>
			<cfbreak>
		</cfif> 
	</cfloop>
	<cfreturn parsedDate.getTime()>
</cffunction>

<cffunction access="public" name="i18nDateTimeParse" output="No" returntype="numeric" hint="parses localized datetime string to datetime object or returns blank if it can't parse"> 
<cfargument name="thisDate" required="yes" type="string">
<cfargument name="thisLocale" required="yes" type="string">
	<cfset var isOk=false>
	<cfset var i=0>
	<cfset var j=0>	
	<cfset var dStyle=0>
	<cfset var tStyle=0>
	<cfset var parsedDate="">
	<cfset var tLocale=aLocale.init(arguments.thisLocale)>	
	<cfset var tDateFormatter="">
	<!--- holy cow batman, can't parse dates in an elegant way. bash! pow! socko! --->
	<cfloop index="i" from="0" to="3">
		<cfset dStyle=javacast("int",i)>
		<cfloop index="j" from="0" to="3">		
			<cfset tStyle=javacast("int",j)>
			<cfset isOK=true>
			<cfset tDateFormatter=aDateFormat.getDateTimeInstance(dStyle,tStyle,tLocale)>
			<cftry>
				<cfset parsedDate=tDateFormatter.parse(arguments.thisDate)>
				<cfcatch type="Any">
					<cfset isOK=false>
				</cfcatch>
			</cftry>
			<cfif isOK>
				<cfbreak>
			</cfif> 
		</cfloop>
	</cfloop>
	<cfreturn parsedDate.getTime()>
</cffunction>

<cffunction access="public" name="getDateTimePattern" output="No" returntype="string" hint="returns locale date/time pattern">
<cfargument name="thisLocale" required="yes" type="string">
<cfargument name="thisDateFormat" required="no" type="numeric" default="1">
<cfargument name="thisTimeFormat" required="no" type="numeric" default="3">
	<cfset var tLocale=aLocale.init(arguments.thisLocale)>
	<cfset var tDateFormat=javacast("int",arguments.thisDateFormat)>
	<cfset var tTimeFormat=javacast("int",arguments.thisTimeFormat)>
	<cfset var tDateFormatter=aDateFormat.getDateTimeInstance(tDateFormat,tTimeFormat,tLocale)>
	<cfreturn tDateFormatter.toPattern()>
</cffunction> 

<cffunction access="public" name="formatDateTime" output="No" returntype="string" hint="formats a date/time to given pattern">
<cfargument name="thisOffset" required="yes" type="numeric">
<cfargument name="thisLocale" required="yes" type="string">
<cfargument name="thisPattern" required="yes" type="string"> 
<cfargument name="tz" required="no" default="#variables.timeZone.getDefault().getDisplayName()#">
	<cfset var tLocale=aLocale.init(arguments.thisLocale)>
	<cfset var tDateFormatter=aDateFormat.getDateTimeInstance(aDateFormat.LONG,aDateFormat.LONG,tLocale)>
	<cfset tDateFormatter.applyPattern(arguments.thisPattern)>
	<cfreturn tDateFormatter.format(arguments.thisOffset)>
</cffunction>

<cffunction access="public" name="getShortWeekDays" output="No" returntype="array" hint="returns short day names for this calendar">
<cfargument name="thisLocale" required="yes" type="string">
<cfargument name="calendarOrder" required="no" type="boolean" default="true">
	<cfset var locale=aLocale.init(arguments.thisLocale)>
	<cfset var thisCalendar=aCalendar.init(utcTZ,locale)>	
	<cfset var theseDateSymbols=dateSymbols.init(thisCalendar,locale)>
	<cfset var localeDays="">
	<cfset var i=0>
	<cfset var tmp=listToArray(arrayToList(theseDateSymbols.getShortWeekDays()))>
	<cfif NOT arguments.calendarOrder>
		<cfreturn tmp>
	<cfelse>
		<cfswitch expression="#weekStarts(arguments.thisLocale)#">
		<cfcase value="1"> <!--- "standard" dates --->
			<cfreturn tmp>
		</cfcase>
		<cfcase value="2"> <!--- euro dates, starts on monday needs kludge --->
			<cfset localeDays=arrayNew(1)>
			<cfset localeDays[7]=tmp[1]>; <!--- move sunday to last --->
			<cfloop index="i" from="1" to="6">
				<cfset localeDays[i]=tmp[i+1]>
			</cfloop>
			<cfreturn localeDays>
		</cfcase>
		<cfcase value="7"> <!--- starts saturday, usually arabic, needs kludge --->
			<cfset localeDays=arrayNew(1)>
			<cfset localeDays[1]=tmp[7]> <!--- move saturday to first --->
			<cfloop index="i" from="1" to="6">
				<cfset localeDays[i+1]=tmp[i]>
			</cfloop>
			<cfreturn localeDays>
		</cfcase>
		</cfswitch>
	</cfif>
</cffunction> 

<cffunction name="getYear" output="No" access="public" returntype="numeric" hint="returns year from epoch offset">
<cfargument name="thisOffset" required="Yes" hint="java epoch offset" type="numeric">
<cfargument name="tz" required="no" default="#variables.timeZone.getDefault().getDisplayName()#">
	<cfset var thisTZ=variables.timeZone.getTimeZone(arguments.tZ)>
	<cfset var thisCalendar=aCalendar.getInstance()>
	<cfset thisCalendar.setTimeInMillis(arguments.thisOffset)>
	<cfset thisCalendar.setTimeZone(thisTZ)>
	<cfreturn thisCalendar.get(thisCalendar.YEAR)>
</cffunction>

<cffunction name="getMonth" output="No" access="public" returntype="numeric" hint="returns month from epoch offset">
<cfargument name="thisOffset" required="Yes" hint="java epoch offset" type="numeric">
<cfargument name="tz" required="no" default="#variables.timeZone.getDefault().getDisplayName()#">
	<cfset var thisTZ=variables.timeZone.getTimeZone(arguments.tZ)>
	<cfset var thisCalendar=aCalendar.getInstance()>
	<cfset thisCalendar.setTimeInMillis(arguments.thisOffset)>
	<cfset thisCalendar.setTimeZone(thisTZ)>
	<cfreturn thisCalendar.get(thisCalendar.MONTH)+1> <!--- java months start at 0 --->
</cffunction>

<cffunction name="getDay" output="No" access="public" returntype="numeric" hint="returns day from epoch offset">
<cfargument name="thisOffset" required="Yes" hint="java epoch offset" type="numeric">
<cfargument name="tz" required="no" default="#variables.timeZone.getDefault().getDisplayName()#">
	<cfset var thisTZ=variables.timeZone.getTimeZone(arguments.tZ)>
	<cfset var thisCalendar=aCalendar.getInstance()>
	<cfset thisCalendar.setTimeInMillis(arguments.thisOffset)>
	<cfset thisCalendar.setTimeZone(thisTZ)>
	<cfreturn thisCalendar.get(thisCalendar.DATE)>
</cffunction>

<cffunction name="getHour" output="No" access="public" returntype="numeric" hint="returns hour of day, 24 hr format, from epoch offset">
<cfargument name="thisOffset" required="Yes" hint="java epoch offset" type="numeric">
<cfargument name="tz" required="no" default="#variables.timeZone.getDefault().getDisplayName()#">
	<cfset var thisTZ=variables.timeZone.getTimeZone(arguments.tZ)>
	<cfset var thisCalendar=aCalendar.getInstance()>
	<cfset thisCalendar.setTimeInMillis(arguments.thisOffset)>
	<cfset thisCalendar.setTimeZone(thisTZ)>
	<cfreturn thisCalendar.get(thisCalendar.HOUR_OF_DAY)>
</cffunction>

<cffunction name="getMinute" output="No" access="public" returntype="numeric" hint="returns minute from epoch offset">
<cfargument name="thisOffset" required="Yes" hint="java epoch offset" type="numeric">
<cfargument name="tz" required="no" default="#variables.timeZone.getDefault().getDisplayName()#">
	<cfset var thisTZ=variables.timeZone.getTimeZone(arguments.tZ)>
	<cfset var thisCalendar=aCalendar.getInstance()>
	<cfset thisCalendar.setTimeInMillis(arguments.thisOffset)>
	<cfset thisCalendar.setTimeZone(thisTZ)>
	<cfreturn thisCalendar.get(thisCalendar.MINUTE)>
</cffunction>

<cffunction name="getSecond" output="No" access="public" returntype="numeric" hint="returns second from epoch offset">
<cfargument name="thisOffset" required="Yes" hint="java epoch offset" type="numeric">
<cfargument name="tz" required="no" default="#variables.timeZone.getDefault().getDisplayName()#">
	<cfset var thisTZ=variables.timeZone.getTimeZone(arguments.tZ)>
	<cfset var thisCalendar=aCalendar.getInstance()>
	<cfset thisCalendar.setTimeInMillis(arguments.thisOffset)>
	<cfset thisCalendar.setTimeZone(thisTZ)>
	<cfreturn thisCalendar.get(thisCalendar.SECOND)>
</cffunction>

<cffunction access="public" name="isMetric" output="false" hint="returns boolean measurement system for given locale" returntype="boolean">
<cfargument name="thisLocale" required="yes" type="string" hint="locale to test measurement system">
<cfscript>
	var locale=aLocale.init(arguments.thisLocale);
	var localeData=aLocaleData.getInstance(locale);
	var thisMS=localeData.getMeasurementSystem(locale);
	if (thisMS EQ thisMS.SI) 
		return true;
	else
		return false;	
</cfscript>
</cffunction>

<cffunction access="public" name="getPaperSize" output="false" hint="returns page size for given locale" returntype="struct">
<cfargument name="thisLocale" required="yes" type="string" hint="locale to find paper size">
<cfscript>
	var paperSize=structNew();
	var locale=aLocale.init(arguments.thisLocale);
	var localeData=aLocaleData.getInstance(locale);
	var thisPS=localeData.getPaperSize(locale);
	paperSize.width=thisPS.getWidth();
	paperSize.height=thisPS.getHeight();
	if (paperSize.width EQ 210 AND paperSize.height EQ 297)
		paperSize.size="A4";
	else
		paperSize.size="Letter";
	return paperSize;
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

<cffunction name="toEpoch" access="public" output="no" returnType="numeric" hint="converts datetime to java epoch offset">
<cfargument name="thisDate" required="Yes" hint="datetime to convert to java epoch" type="date">
	<cfreturn arguments.thisDate.getTime()>
 </cffunction>
 
<cffunction name="fromEpoch" access="public" output="no" returnType="date" hint="converts java epoch offset to datetime">
<cfargument name="thisOffset" required="Yes" hint="java epoch offset to convert to datetime" type="numeric">
	<cfset var thisCalendar=aCalendar.getInstance()>
	<cfset thisCalendar.setTimeInMillis(arguments.thisOffset)>
	<cfreturn thisCalendar.getTime()>
 </cffunction>

<cffunction access="public" name="getTZByCountry" output="No" hint="gets timezone by country" returntype="array">
<cfargument name="country" required="yes" type="string" hint="2-letter ISO country code to get timezone for">
	<cfreturn variables.timeZone.getAvailableIDs(arguments.country)>
</cffunction>

<cffunction name="getAvailableTZ" output="yes" returntype="array" access="public" hint="returns an array of timezones available on this server">
		<cfreturn variables.timeZone.getAvailableIDs()>
</cffunction>

<cffunction name="usesDST" output="No" returntype="boolean" access="public" hint="determines if a given timezone uses DST">
<cfargument name="tz" required="no" default="#variables.timeZone.getDefault().getDisplayName()#">
	<cfreturn variables.timeZone.getTimeZone(arguments.tz).useDaylightTime()>
</cffunction>

<cffunction name="getRawOffset" output="No" access="public" returntype="numeric" hint="returns rawoffset in hours">
<cfargument name="tZ" required="no" default="#variables.timeZone.getDefault().getDisplayName()#">
		<cfset var thisTZ=variables.timeZone.getTimeZone(arguments.tZ)>
		<cfreturn thisTZ.getRawOffset()/3600000>
</cffunction>

<cffunction name="getDST" output="No" access="public" returntype="numeric" hint="returns DST savings in hours">  
<cfargument name="thisTZ" required="no" default="#variables.timeZone.getDefault().getDisplayName()#">
	<cfset var tZ=variables.timeZone.getTimeZone(arguments.thisTZ)>
	<cfreturn tZ.getDSTSavings()/3600000>
</cffunction>

<cffunction name="getTZByOffset" output="No" returntype="array" access="public" hint="returns a list of timezones available on this server for a given raw offset">  
<cfargument name="thisOffset" required="Yes" type="numeric">
	<cfset var rawOffset=javacast("long",arguments.thisOffset * 3600000)>
	<cfreturn variables.timeZone.getAvailableIDs(rawOffset)>
</cffunction>

<cffunction name="getServerTZ" output="No" access="public" returntype="any" hint="returns server TZ">
	<cfset serverTZ=variables.timeZone.getDefault()>
	<cfreturn serverTZ.getDisplayName(true,variables.timeZone.LONG)>
</cffunction>

<cffunction name="inDST" output="No" returntype="boolean" access="public" hint="determines if a given date in a given timezone is in DST">
<cfargument name="thisOffset" required="yes" type="numeric">
<cfargument name="tzToTest" required="no" default="#variables.timeZone.getDefault().getID()#">
	<cfset var thisTZ=variables.timeZone.getTimeZone(arguments.tzToTest)>
	<cfset var thisCalendar=aCalendar.getInstance()>
	<cfset thisCalendar.setTimeInMillis(arguments.thisOffset)>
	<cfset thisCalendar.setTimezone(thisTZ)>
	<cfreturn thisTZ.inDaylightTime(thisCalendar.getTime())>
</cffunction>

<cffunction name="getTZOffset" output="No" access="public" returntype="numeric" hint="returns offset in hours">  
<cfargument name="thisOffset" required="yes" type="numeric">
<cfargument name="thisTZ" required="no" default="#variables.timeZone.getDefault().getDisplayName()#">
	<cfset var tZ=variables.timeZone.getTimeZone(arguments.thisTZ)>;
	<cfreturn tZ.getOffset(arguments.thisOffset)/3600000> <!--- return hours --->
</cffunction>

</cfcomponent>

