<cfcomponent output="false">

<!--- CONSTRUCTOR --->
	<cffunction name="init" access="public" returntype="any" output="false">
		<cfargument name="apiKey"        type="string" required="true" />
		<cfargument name="defaultDomain" type="string" required="false" default="" />
		<cfargument name="baseUrl"       type="string" required="false" default="https://api.mailgun.net/v2" />

		<cfscript>
			_setApiKey ( arguments.apiKey  );
			_setDefaultDomain( arguments.defaultDomain );
			_setBaseUrl( arguments.baseUrl );

			return this;
		</cfscript>
	</cffunction>

<!--- PUBLIC API METHODS --->



<!--- PRIVATE HELPERS --->

<!--- GETTERS AND SETTERS --->
	<cffunction name="_getApiKey" access="private" returntype="string" output="false">
		<cfreturn _apiKey>
	</cffunction>
	<cffunction name="_setApiKey" access="private" returntype="void" output="false">
		<cfargument name="apiKey" type="string" required="true" />
		<cfset _apiKey = arguments.apiKey />
	</cffunction>

	<cffunction name="_getDefaultDomain" access="private" returntype="string" output="false">
		<cfreturn _defaultDomain>
	</cffunction>
	<cffunction name="_setDefaultDomain" access="private" returntype="void" output="false">
		<cfargument name="defaultDomain" type="string" required="true" />
		<cfset _defaultDomain = arguments.defaultDomain />
	</cffunction>

	<cffunction name="_getBaseUrl" access="private" returntype="string" output="false">
		<cfreturn _baseUrl>
	</cffunction>
	<cffunction name="_setBaseUrl" access="private" returntype="void" output="false">
		<cfargument name="baseUrl" type="string" required="true" />
		<cfset _baseUrl = arguments.baseUrl />
	</cffunction>


</cfcomponent>