<cfcomponent output="false">

	<cfscript>
		statusCodes = StructNew();
	</cfscript>

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
			_setForceTestMode( arguments.forceTestMode );
			_setBaseUrl( arguments.baseUrl );
			_setHttpTimeout( arguments.httpTimeout );

			return this;
		</cfscript>
	</cffunction>

<!--- PUBLIC API METHODS --->
	<cffunction name="sendMessage" access="public" returntype="string" output="false" hint="Attempts to send a message through the MailGun API - returns message if successul and throws an error otherwise">
		<cfargument name="from"              type="string"  required="true" />
		<cfargument name="to"                type="string"  required="true" />
		<cfargument name="subject"           type="string"  required="true" />
		<cfargument name="text"              type="string"  required="true" />
		<cfargument name="html"              type="string"  required="true" />
		<cfargument name="cc"                type="string"  required="false" default="" />
		<cfargument name="bcc"               type="string"  required="false" default="" />
		<cfargument name="attachments"       type="array"   required="false" default="#ArrayNew(1)#" />
		<cfargument name="inlineAttachments" type="array"   required="false" default="#ArrayNew(1)#" />
		<cfargument name="domain"            type="string"  required="false" default="#_getDefaultDomain()#" />
		<cfargument name="testMode"          type="boolean" required="false" default="false" />

		<cfscript>
			var result   = "";
			var files    = {};
			var postVars = {
				  from    = arguments.from
				, to      = arguments.to
				, subject = arguments.subject
				, text    = arguments.text
				, html    = arguments.html
			};

			postVars[ "o:testmode" ] = _getForceTestMode() or arguments.testMode;

			if ( Len( Trim( arguments.cc ) ) ) {
				postVars.cc = arguments.cc;
			}

			if ( Len( Trim( arguments.bcc ) ) ) {
				postVars.bcc = arguments.bcc;
			}

			if ( ArrayLen( arguments.attachments ) ) {
				files.attachment = arguments.attachments;
			}

			if ( ArrayLen( arguments.inlineAttachments ) ) {
				files.inline = arguments.inlineAttachments;
			}

			result = _restCall(
				  httpMethod = "POST"
				, uri        = "/messages"
				, domain     = arguments.domain
				, postVars   = postVars
				, files      = files
			);

			if ( StructKeyExists( result, "id" ) ) {
				return result.id;
			}

			_throw(
				  type    = "unexpected"
				, message = "Unexpected error processing mail send."
				, detail  = "Expected an ID of successfully sent mail but instead received [#SerializeJson( result )#]"
			);
		</cfscript>
	</cffunction>



<!--- PRIVATE HELPERS --->
	<cffunction name="_restCall" access="private" returntype="struct" output="false">
		<cfargument name="httpMethod" type="string" required="true" />
		<cfargument name="uri"        type="string" required="true" />
		<cfargument name="domain"     type="string" required="false" default="" />
		<cfargument name="postVars"   type="struct" required="false" default="#StructNew()#" />
		<cfargument name="files"      type="struct" required="false" default="#StructNew()#" />

		<cfset var httpResult = "" />
		<cfset var key        = "" />
		<cfset var i  = "" />

		<cfhttp url       = "#_getRestUrl( arguments.uri, arguments.domain )#"
		        method    = "#arguments.httpMethod#"
		        username  = "api"
		        password  = "#_getApiKey()#"
		        timeout   = "#_getHttpTimeout()#"
		        result    = "httpResult"
		        multipart = "#( StructCount( arguments.files) gt 0 )#">

			<cfloop collection="#arguments.postVars#" item="key">
				<cfif IsArray( arguments.postVars[ key ] )>
					<cfloop from="1" to="#ArrayLen( arguments.postVars[ key ] )#" index="i">
						<cfhttpparam type="formfield" name="#key#" value="#arguments.postVars[ key ][ i ]#" />
					</cfloop>
				<cfelse>
					<cfhttpparam type="formfield" name="#key#" value="#arguments.postVars[ key ]#" />
				</cfif>
			</cfloop>

			<cfloop collection="#arguments.files#" item="key">
				<cfif IsArray( arguments.files[ key ] )>
					<cfloop from="1" to="#ArrayLen( arguments.files[ key ] )#" index="i">
						<cfhttpparam type="file" name="#key#" file="#arguments.files[ key ][i]#" />
					</cfloop>
				<cfelse>
					<cfhttpparam type="file" name="#key#" file="#arguments.files[ key ]#" />
				</cfif>
			</cfloop>
		</cfhttp>

		<cfreturn _processApiResponse( argumentCollection=httpResult ) />
	</cffunction>

	<cffunction name="_processApiResponse" access="private" returntype="any" output="false">
		<cfargument name="filecontent" type="string" required="false" default="" />
		<cfargument name="status_code" type="string" required="false" default="" />


		<cfscript>
			_checkErrorStatusCodes( argumentCollection = arguments );

			try {
				return DeserializeJSON( arguments.fileContent );

			} catch ( any e ) {
				_throw(
					  type    = "unexpected"
					, message = "Unexpected error processing MailGun API response."
					, detail  = "MailGun response body: #arguments.fileContent#"
				);
			}
	</cfscript>
	</cffunction>

	<cffunction name="_checkErrorStatusCodes" access="private" returntype="void" output="false">
		<cfargument name="status_code" type="string" required="true" />
		<cfargument name="filecontent" type="string" required="true" />

		<cfscript>
			var errorParams = {};
			var deserialized = "";

			if ( arguments.status_code NEQ 200 ) {
				try {
					deserialized = DeserializeJson( arguments.fileContent );
				} catch ( any e ){}

				if ( IsStruct( deserialized ) and StructKeyExists( deserialized, "message" ) ) {
					errorParams.detail    = deserialized.message
				} else {
					errorParams.detail    = "MailGun response body: [#arguments.filecontent#]"
				}

				if ( Val( arguments.status_code ) ) {
					errorParams.errorCode = arguments.status_code;
				} else {
					errorParams.errorCode = 500;
				}

				switch( arguments.status_code ) {
					case 400:
						errorParams.type    = "badrequest";
						errorParams.message = "MailGun request failure. Often caused by bad or missing parameters. See detail for full MailGun response.";
					break;

					case 401:
						errorParams.type    = "unauthorized";
						errorParams.message = "MailGun authentication failure, i.e. a bad API Key was supplied";
					break;

					case 402:
						errorParams.type    = "requestfailed";
						errorParams.message = "MailGun request failed (unexpected)";
					break;

					case 404:
						errorParams.type    = "resourcenotfound";
						errorParams.message = "MailGun requested resource not found (404). This might be caused by an invalid domain or incorrectly programmed API call.";
						errorParams.detail  = "";
					break;

					case 500: case 502: case 503: case 504:
						errorParams.type    = "mailgun.server.error";
						errorParams.message = "An unexpected error occurred on the MailGun server";
					break;

					default:
						errorParams.type    = "unexpected";
						errorParams.message = "An unexpted response was returned from the MailGun server";

				}

				_throw( argumentCollection = errorParams );
			}
		</cfscript>
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

	<cffunction name="_throw" access="private" returntype="void" output="false">
		<cfargument name="type" type="string" required="true" />
		<cfargument name="message" type="string" required="false" default="" />
		<cfargument name="detail" type="string" required="false" default="" />
		<cfargument name="errorcode" type="numeric" required="false" default="500" />

		<cfthrow type="cfmailgun.#arguments.type#" message="#arguments.message#" detail="#arguments.detail#" errorcode="#arguments.errorCode#" />
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