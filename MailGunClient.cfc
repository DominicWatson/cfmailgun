<cfcomponent output="false">

<!--- CONSTRUCTOR --->
	<cffunction name="init" access="public" returntype="any" output="false">
		<cfargument name="apiKey"        type="string"  required="true" />
		<cfargument name="defaultDomain" type="string"  required="false" default="" />
		<cfargument name="baseUrl"       type="string"  required="false" default="https://api.mailgun.net/v2" />
		<cfargument name="forceTestMode" type="boolean" required="false" default="false" />
		<cfargument name="httpTimeout"   type="numeric" required="false" default="60" />

		<cfscript>
			_setApiKey ( arguments.apiKey  );
			_setDefaultDomain( arguments.defaultDomain );
			_setForceTestMode( arguments.testMode );
			_setBaseUrl( arguments.baseUrl );
			_setHttpTimeout( arguments.httpTimeout );

			return this;
		</cfscript>
	</cffunction>

<!--- PUBLIC API METHODS --->



<!--- PRIVATE HELPERS --->
	<cffunction name="_restCall" access="private" returntype="struct" output="false">
		<cfargument name="httpMethod" type="string" required="true" />
		<cfargument name="uri"        type="string" required="true" />
		<cfargument name="domain"     type="string" required="false" default="" />
		<cfargument name="postVars"   type="struct" required="false" default="#StructNew()#" />
		<cfargument name="files"      type="struct" required="false" default="#StructNew()#" />

		<cfset var httpResult = "" />
		<cfset var key        = "" />
		<cfset var arrayItem  = "" />

		<cfhttp url       = "#_getRestUrl( arguments.uri, arguments.domain )#"
		        method    = "#arguments.httpMethod#"
		        username  = "api"
		        password  = "#_getApiKey()#"
		        timeout   = "#_getHttpTimeout()#"
		        result    = "httpResult"
		        multipart = "#( StructCount( arguments.files) gt 0 )#">

			<cfloop collection="#arguments.postVars#" item="key">
				<cfif IsArray( arguments.postVars[ key ] )>
					<cfloop array="#arguments.postVars[ key ]#" index="arrayItem">
						<cfhttpparam type="formfield" name="#key#" value="#arrayItem#" />
					</cfloop>
				<cfelse>
					<cfhttpparam type="formfield" name="#key#" value="#arguments.postVars[ key ]#" />
				</cfif>
			</cfloop>

			<cfloop collection="#arguments.files#" item="key">
				<cfif IsArray( arguments.files[ key ] )>
					<cfloop array="#arguments.files[ key ]#" index="arrayItem">
						<cfhttpparam type="file" name="#key#" value="#arrayItem#" />
					</cfloop>
				<cfelse>
					<cfhttpparam type="file" name="#key#" value="#arguments.files[ key ]#" />
				</cfif>
			</cfloop>
		</cfhttp>

		<cfreturn httpResult />
	</cffunction>

	<cffunction name="_getRestUrl" access="private" returntype="string" output="false">
		<cfargument name="uri"    type="string" required="true" />
		<cfargument name="domain" type="string" required="true" />

		<cfscript>
			var restUrl = _getBaseUrl();

			if ( Len( Trim( arguments.domain ) ) ) {
				restUrl &= "/" & arguments.domain;
			}

			restUrl &= arguments.uri;

			return restUrl;
		</cfscript>
	</cffunction>

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

	<cffunction name="_getForceTestMode" access="private" returntype="boolean" output="false">
		<cfreturn _forceTestMode>
	</cffunction>
	<cffunction name="_setForceTestMode" access="private" returntype="void" output="false">
		<cfargument name="forceTestMode" type="boolean" required="true" />
		<cfset _forceTestMode = arguments.forceTestMode />
	</cffunction>

	<cffunction name="_getBaseUrl" access="private" returntype="string" output="false">
		<cfreturn _baseUrl>
	</cffunction>
	<cffunction name="_setBaseUrl" access="private" returntype="void" output="false">
		<cfargument name="baseUrl" type="string" required="true" />
		<cfset _baseUrl = arguments.baseUrl />
	</cffunction>

	<cffunction name="_getHttpTimeout" access="private" returntype="numeric" output="false">
		<cfreturn _httpTimeout>
	</cffunction>
	<cffunction name="_setHttpTimeout" access="private" returntype="void" output="false">
		<cfargument name="httpTimeout" type="numeric" required="true" />
		<cfset _httpTimeout = arguments.httpTimeout />
	</cffunction>

</cfcomponent>