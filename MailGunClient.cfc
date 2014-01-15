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
			_setForceTestMode( arguments.forceTestMode );
			_setBaseUrl( arguments.baseUrl );
			_setHttpTimeout( arguments.httpTimeout );

			return this;
		</cfscript>
	</cffunction>

<!--- MESSAGES --->
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
		<cfargument name="tags"              type="array"   required="false" default="#ArrayNew(1)#" />
		<cfargument name="campaign"          type="string"  required="false" default="" />
		<cfargument name="dkim"              type="string"  required="false" default="" />
		<cfargument name="deliveryTime"      type="string"  required="false" default="" />
		<cfargument name="tracking"          type="string"  required="false" default="" />
		<cfargument name="clickTracking"     type="string"  required="false" default="" />
		<cfargument name="openTracking"      type="string"  required="false" default="" />
		<cfargument name="customHeaders"     type="struct"  required="false" default="#StructNew()#" />
		<cfargument name="customVariables"   type="struct"  required="false" default="#StructNew()#" />

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

			if ( Len( Trim( arguments.cc ) ) ) {
				postVars.cc = arguments.cc;
			}

			if ( Len( Trim( arguments.bcc ) ) ) {
				postVars.bcc = arguments.bcc;
			}

			if ( _getForceTestMode() or arguments.testMode ) {
				postVars[ "o:testmode" ] = "yes";
			}

			if ( ArrayLen( arguments.tags ) ) {
				postVars[ "o:tag" ] = arguments.tags;
			}

			if ( Len( Trim( arguments.campaign ) ) ) {
				postVars[ "o:campaign" ] = arguments.campaign;
			}

			if ( IsBoolean( arguments.dkim ) ) {
				postVars[ "o:dkim" ] = _boolFormat( arguments.dkim );
			}

			if ( IsDate( arguments.deliveryTime ) ) {
				postVars[ "o:deliverytime" ] = _dateFormat( arguments.deliveryTime );
			}

			if ( IsBoolean( arguments.tracking ) ) {
				postVars[ "o:tracking" ] = _boolFormat( arguments.tracking );
			}

			if ( IsBoolean( arguments.clickTracking ) ) {
				postVars[ "o:tracking-clicks" ] = _boolFormat( arguments.clickTracking );
			} elseif( arguments.clickTracking eq "htmlonly" ) {
				postVars[ "o:tracking-clicks" ] = "htmlonly";
			}

			if ( IsBoolean( arguments.openTracking ) ) {
				postVars[ "o:tracking-opens" ] = _boolFormat( arguments.openTracking );
			}

			for( var key in arguments.customHeaders ){
				postVars[ "h:X-#key#" ] = arguments.customHeaders[ key ];
			}

			for( var key in arguments.customVariables ){
				postVars[ "v:#key#" ] = arguments.customVariables[ key ];
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
				, message = "Unexpected error processing mail send. Expected an ID of successfully sent mail but instead received [#SerializeJson( result )#]"
			);
		</cfscript>
	</cffunction>

<!--- CAMPAIGNS --->
	<cffunction name="listCampaigns" access="public" returntype="struct" output="false">
		<cfargument name="domain" type="string"  required="false" default="#_getDefaultDomain()#" />
		<cfargument name="limit"  type="numeric" required="false" />
		<cfargument name="skip"   type="numeric" required="false" />

		<cfscript>
			var result  = "";
			var getVars = {};

			if ( StructKeyExists( arguments, "limit" ) ) {
				getVars.limit = arguments.limit;
			}
			if ( StructKeyExists( arguments, "skip" ) ) {
				getVars.skip = arguments.skip;
			}

			result = _restCall(
				  httpMethod = "GET"
				, uri        = "/campaigns"
				, domain     = arguments.domain
				, getVars    = getVars
			);

			if ( StructKeyExists( result, "total_count" ) and StructKeyExists( result, "items" ) ) {
				return result;
			}

			_throw(
				  type      = "unexpected"
				, errorCode = 500
				, message   = "Expected response to contain [total_count] and [items] keys. Instead, receieved: [#SerializeJson( result )#]" )

		</cfscript>
	</cffunction>

	<cffunction name="getCampaign" access="public" returntype="struct" output="false">
		<cfargument name="id"     type="string" required="true" />
		<cfargument name="domain" type="string" required="false" default="#_getDefaultDomain()#" />

		<cfscript>
			var result = _restCall(
				  httpMethod = "GET"
				, uri        = "/campaigns/#arguments.id#"
				, domain     = arguments.domain
			);

			if ( IsStruct( result ) and StructKeyExists( result, "id" ) and StructKeyExists( result, "name" ) ) {
				return result;
			}

			_throw(
				  type      = "unexpected"
				, message   = "Unexpected mailgun response. Expected a campaign object (structure) but received: [#SerializeJson( result )#]"
				, errorCode = 500
			);
		</cfscript>
	</cffunction>

	<cffunction name="createCampaign" access="public" returntype="any" output="false">
		<cfargument name="name"   type="string" required="true" />
		<cfargument name="id"     type="string" required="false" default="" />
		<cfargument name="domain" type="string" required="false" default="#_getDefaultDomain()#" />

		<cfscript>
			var postVars = { name=arguments.name }
			var result   = "";

			if ( Len( Trim( arguments.id ) ) ) {
				postVars[ "id" ] = arguments.id;
			}

			result = _restCall(
				  httpMethod = "POST"
				, uri        = "/campaigns"
				, domain     = arguments.domain
				, postVars   = postVars
			);

			if ( IsStruct( result ) and StructKeyExists( result, "message" ) and StructKeyExists( result, "campaign" ) ) {
				return result;
			}

			_throw(
				  type      = "unexpected"
				, message   = "CreateCampaign() response was an in an unexpected format. Expected success message and campaign detail. Instead, recieved: [#SerializeJson( result )#]"
				, errorCode = 500
			);
		</cfscript>
	</cffunction>

	<cffunction name="updateCampaign" access="public" returntype="struct" output="false">
		<cfargument name="id"     type="string" required="true" />
		<cfargument name="name"   type="string" required="false" />
		<cfargument name="newId"  type="string" required="false" default="" />
		<cfargument name="domain" type="string" required="false" default="#_getDefaultDomain()#" />

		<cfscript>
			var result  = "";
			var getVars = {};

			if ( Len( Trim( arguments.name ) ) ) {
				getVars.name = arguments.name;
			}

			if ( Len( Trim( arguments.newId ) ) ) {
				getVars.id = arguments.newId;
			}

			result = _restCall(
				  httpMethod = "PUT"
				, uri        = "/campaigns/#arguments.id#"
				, domain     = arguments.domain
				, getVars    = getVars
			);

			if ( IsStruct( result ) and StructKeyExists( result, "message" ) and StructKeyExists( result, "campaign" ) ) {
				return result;
			}

			_throw(
				  type      = "unexpected"
				, message   = "UpdateCampaign() response was an in an unexpected format. Expected success message and campaign detail. Instead, recieved: [#SerializeJson( result )#]"
				, errorCode = 500
			);
		</cfscript>
	</cffunction>

	<cffunction name="deleteCampaign" access="public" returntype="struct" output="false">
		<cfargument name="id"     type="string" required="true" />
		<cfargument name="domain" type="string" required="false" default="#_getDefaultDomain()#" />

		<cfscript>
			var result = _restCall(
				  httpMethod = "DELETE"
				, uri        = "/campaigns/#arguments.id#"
				, domain     = arguments.domain
			);

			if ( IsStruct( result ) and StructKeyExists( result, "message" ) and StructKeyExists( result, "id" ) ) {
				return result;
			}

			_throw(
				  type      = "unexpected"
				, message   = "DeleteCampaign() response was an in an unexpected format. Expected success message and campaign id. Instead, recieved: [#SerializeJson( result )#]"
				, errorCode = 500
			);
		</cfscript>
	</cffunction>

<!--- MAILING LISTS --->
	<cffunction name="listMailingLists" access="public" returntype="struct" output="false">
		<cfargument name="limit"  type="numeric" required="false" />
		<cfargument name="skip"   type="numeric" required="false" />

		<cfscript>
			var result  = "";
			var getVars = {};

			if ( StructKeyExists( arguments, "limit" ) ) {
				getVars.limit = arguments.limit;
			}
			if ( StructKeyExists( arguments, "skip" ) ) {
				getVars.skip = arguments.skip;
			}

			result = _restCall(
				  httpMethod = "GET"
				, uri        = "/lists"
				, domain     = ""
				, getVars    = getVars
			);

			if ( StructKeyExists( result, "total_count" ) and StructKeyExists( result, "items" ) ) {
				return result;
			}

			_throw(
				  type      = "unexpected"
				, errorCode = 500
				, message   = "Expected response to contain [total_count] and [items] keys. Instead, receieved: [#SerializeJson( result )#]"
			);
		</cfscript>
	</cffunction>

	<cffunction name="getMailingList" access="public" returntype="struct" output="false">
		<cfargument name="address" type="string" required="true" />

		<cfscript>
			var result = _restCall(
				  httpMethod = "GET"
				, uri        = "/lists/#arguments.address#"
				, domain     = ""
			);

			if ( IsStruct( result ) and StructKeyExists( result, "list" ) and IsStruct( result.list ) and StructKeyExists( result.list, "address" ) ) {
				return result.list;
			}

			_throw(
				  type      = "unexpected"
				, errorCode = 500
				, message   = "Unexpected mailgun response. Expected a mailing list object (structure) but received: [#SerializeJson( result )#]"
			);
		</cfscript>
	</cffunction>

	<cffunction name="createMailingList" access="public" returntype="struct" output="false">
		<cfargument name="address"     type="string" required="true" />
		<cfargument name="name"        type="string" required="false" default="" />
		<cfargument name="description" type="string" required="false" default="" />
		<cfargument name="accessLevel" type="string" required="false" default="" />

		<cfscript>
			var postVars = { address = arguments.address };
			var result   = "";

			if ( Len( Trim( arguments.name ) ) ) {
				postVars[ "name" ] = arguments.name;
			}
			if ( Len( Trim( arguments.description ) ) ) {
				postVars[ "description" ] = arguments.description;
			}
			if ( Len( Trim( arguments.accessLevel ) ) ) {
				postVars[ "access_level" ] = arguments.accessLevel;
			}

			result = _restCall(
				  httpMethod = "POST"
				, uri        = "/lists"
				, domain     = ""
				, postVars   = postVars
			);

			if ( IsStruct( result ) and StructKeyExists( result, "message" ) and StructKeyExists( result, "list" ) ) {
				return result;
			}

			_throw(
				  type      = "unexpected"
				, message   = "CreateMailingList() response was an in an unexpected format. Expected success message and list detail. Instead, recieved: [#SerializeJson( result )#]"
				, errorCode = 500
			);
		</cfscript>
	</cffunction>

	<cffunction name="updateMailingList" access="public" returntype="struct" output="false">
		<cfargument name="address"     type="string" required="true" />
		<cfargument name="newAddress"  type="string" required="false" default="" />
		<cfargument name="name"        type="string" required="false" default="" />
		<cfargument name="description" type="string" required="false" default="" />
		<cfargument name="accessLevel" type="string" required="false" default="" />

		<cfscript>
			var result  = "";
			var getVars = {};

			if ( Len( Trim( arguments.newAddress ) ) ) {
				getVars[ "address" ] = arguments.newAddress;
			}
			if ( Len( Trim( arguments.name ) ) ) {
				getVars[ "name" ] = arguments.name;
			}
			if ( Len( Trim( arguments.description ) ) ) {
				getVars[ "description" ] = arguments.description;
			}
			if ( Len( Trim( arguments.accessLevel ) ) ) {
				getVars[ "access_level" ] = arguments.accessLevel;
			}

			result = _restCall(
				  httpMethod = "PUT"
				, uri        = "/lists/#arguments.address#"
				, domain     = ""
				, getVars    = getVars
			);

			if ( IsStruct( result ) and StructKeyExists( result, "message" ) and StructKeyExists( result, "list" ) ) {
				return result;
			}

			_throw(
				  type      = "unexpected"
				, message   = "UpdateMailingList() response was an in an unexpected format. Expected success message and list detail. Instead, recieved: [#SerializeJson( result )#]"
				, errorCode = 500
			);

			return result;
		</cfscript>
	</cffunction>

	<cffunction name="deleteMailingList" access="public" returntype="struct" output="false">
		<cfargument name="address" type="string" required="true" />

		<cfscript>
			var result = _restCall(
				  httpMethod = "DELETE"
				, uri        = "/lists/#arguments.address#"
				, domain     = ""
			);

			if ( IsStruct( result ) and StructKeyExists( result, "message" ) and StructKeyExists( result, "address" ) ) {
				return result;
			}

			_throw(
				  type      = "unexpected"
				, message   = "DeleteMailingList() response was an in an unexpected format. Expected success message and list address. Instead, recieved: [#SerializeJson( result )#]"
				, errorCode = 500
			);
		</cfscript>
	</cffunction>

	<cffunction name="listMailingListMembers" access="public" returntype="struct" output="false">
		<cfargument name="address"    type="string"  required="true" />
		<cfargument name="limit"      type="numeric" required="false" />
		<cfargument name="skip"       type="numeric" required="false" />
		<cfargument name="subscribed" type="boolean" required="false" />

		<cfscript>
			var result  = "";
			var getVars = {};

			if ( StructKeyExists( arguments, "limit" ) ) {
				getVars[ "limit" ] = arguments.limit;
			}
			if ( StructKeyExists( arguments, "skip" ) ) {
				getVars[ "skip" ] = arguments.skip;
			}
			if ( StructKeyExists( arguments, "subscribed" ) ) {
				getVars[ "subscribed" ] = _boolFormat( arguments.subscribed );
			}

			result = _restCall(
				  httpMethod = "GET"
				, uri        = "/lists/#arguments.address#/members"
				, domain     = ""
				, getVars    = getVars
			);

			if ( IsStruct( result ) and StructKeyExists( result, "total_count" ) and StructKeyExists( result, "items" ) ) {
				return result;
			}

			_throw(
				  type      = "unexpected"
				, message   = "ListMailingListMembers() response was an in an unexpected format. Expected list of addresses. Instead, recieved: [#SerializeJson( result )#]"
				, errorCode = 500
			);
		</cfscript>
	</cffunction>

	<cffunction name="getMailingListMember" access="public" returntype="struct" output="false">
		<cfargument name="listAddress"   type="string" required="true" />
		<cfargument name="memberAddress" type="string" required="true" />

		<cfscript>
			var result = _restCall(
				  httpMethod = "GET"
				, uri        = "/lists/#arguments.listAddress#/members/#arguments.memberAddress#"
				, domain     = ""
			);

			if ( IsStruct( result ) and StructKeyExists( result, "member" ) ) {
				return result;
			}

			_throw(
				  type      = "unexpected"
				, message   = "GetMailingListMember() response was an in an unexpected format. Expected member structure. Instead, recieved: [#SerializeJson( result )#]"
				, errorCode = 500
			);
		</cfscript>
	</cffunction>

	<cffunction name="createMailingListMember" access="public" returntype="struct" output="false">
		<cfargument name="listAddress"   type="string"  required="true" />
		<cfargument name="memberAddress" type="string"  required="true" />
		<cfargument name="name"          type="string"  required="false" default="" />
		<cfargument name="vars"          type="struct"  required="false" />
		<cfargument name="subscribed"    type="boolean" required="false" />
		<cfargument name="upsert"        type="boolean" required="false" />

		<cfscript>
			var result   = "";
			var postVars = { address = arguments.memberAddress };

			if ( Len( Trim( arguments.name ) ) ) {
				postVars[ "name" ] = arguments.name;
			}

			if ( StructKeyExists( arguments, "vars" ) ) {
				postVars[ "vars" ] = SerializeJson( arguments.vars );
			}
			if ( StructKeyExists( arguments, "subscribed" ) ) {
				postVars[ "subscribed" ] = _boolFormat( arguments.subscribed );
			}
			if ( StructKeyExists( arguments, "upsert" ) ) {
				postVars[ "upsert" ] = _boolFormat( arguments.upsert );
			}

			result = _restCall(
				  httpMethod = "POST"
				, uri        = "/lists/#arguments.listAddress#/members"
				, postVars   = postVars
				, domain     = ""
			);

			if ( IsStruct( result ) and StructKeyExists( result, "message" ) and StructKeyExists( result, "member" ) ) {
				return result;
			}

			_throw(
				  type      = "unexpected"
				, message   = "CreateMailingListMember() response was an in an unexpected format. Expected success message and member detail. Instead, recieved: [#SerializeJson( result )#]"
				, errorCode = 500
			);
		</cfscript>
	</cffunction>

	<cffunction name="updateMailingListMember" access="public" returntype="struct" output="false">
		<cfargument name="listAddress"   type="string"  required="true" />
		<cfargument name="memberAddress" type="string"  required="true" />
		<cfargument name="newAddress"    type="string"  required="false" default="" />
		<cfargument name="name"          type="string"  required="false" default="" />
		<cfargument name="vars"          type="struct"  required="false" />
		<cfargument name="subscribed"    type="boolean" required="false" />

		<cfscript>
			var result = "";
			var getVars = {};

			if( Len( Trim( arguments.newAddress ) ) ) {
				getVars[ "address" ] = arguments.newAddress;
			}
			if( Len( Trim( arguments.name ) ) ) {
				getVars[ "name" ] = arguments.name;
			}
			if( StructKeyExists( arguments, "vars" ) ) {
				getVars[ "vars" ] = SerializeJson( arguments.vars );
			}
			if( StructKeyExists( arguments, "subscribed" ) ) {
				getVars[ "subscribed" ] = _boolFormat( arguments.subscribed );
			}

			result = _restCall(
				  httpMethod = "PUT"
				, uri        = "/lists/#arguments.listAddress#/members/#arguments.memberAddress#"
				, domain     = ""
				, getVars    = getVars
			);

			if ( IsStruct( result ) and StructKeyExists( result, "message" ) and StructKeyExists( result, "member" ) ) {
				return result;
			}

			_throw(
				  type      = "unexpected"
				, message   = "UpdateMailingListMember() response was an in an unexpected format. Expected success message and member detail. Instead, recieved: [#SerializeJson( result )#]"
				, errorCode = 500
			);

			return result;
		</cfscript>
	</cffunction>

	<cffunction name="deleteMailingListMember" access="public" returntype="struct" output="false">
		<cfargument name="listAddress"   type="string"  required="true" />
		<cfargument name="memberAddress" type="string"  required="true" />

		<cfscript>
			var result = _restCall(
				  httpMethod = "DELETE"
				, uri        = "/lists/#arguments.listAddress#/members/#arguments.memberAddress#"
				, domain     = ""
			);

			if ( IsStruct( result ) and StructKeyExists( result, "message" ) and StructKeyExists( result, "member" ) and IsStruct( result.member ) and StructKeyExists( result.member, "address" ) ) {
				return result;
			}

			_throw(
				  type      = "unexpected"
				, message   = "DeleteMailingListMember() response was an in an unexpected format. Expected success message and member address. Instead, recieved: [#SerializeJson( result )#]"
				, errorCode = 500
			);
		</cfscript>
	</cffunction>

<!--- PRIVATE HELPERS --->
	<cffunction name="_restCall" access="private" returntype="struct" output="false">
		<cfargument name="httpMethod" type="string" required="true" />
		<cfargument name="uri"        type="string" required="true" />
		<cfargument name="domain"     type="string" required="false" default="" />
		<cfargument name="postVars"   type="struct" required="false" default="#StructNew()#" />
		<cfargument name="getVars"    type="struct" required="false" default="#StructNew()#" />
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
						<cfhttpparam type name="#key#" value="#arguments.postVars[ key ][ i ]#" />
					</cfloop>
				<cfelse>
					<cfhttpparam type="formfield" name="#key#" value="#arguments.postVars[ key ]#" />
				</cfif>
			</cfloop>

			<cfloop collection="#arguments.getVars#" item="key">
				<cfif IsArray( arguments.getVars[ key ] )>
					<cfloop from="1" to="#ArrayLen( arguments.getVars[ key ] )#" index="i">
						<cfhttpparam type="url" name="#key#" value="#arguments.getVars[ key ][ i ]#" />
					</cfloop>
				<cfelse>
					<cfhttpparam type="url" name="#key#" value="#arguments.getVars[ key ]#" />
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
					, message = "Unexpected error processing MailGun API response. MailGun response body: [#arguments.fileContent#]"
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
				switch( arguments.status_code ) {
					case 400:
						errorParams.type    = "badrequest";
						errorParams.message = "MailGun request failure. ";
					break;

					case 401:
						errorParams.type    = "unauthorized";
						errorParams.message = "MailGun authentication failure, i.e. a bad API Key was supplied. ";
					break;

					case 402:
						errorParams.type    = "requestfailed";
						errorParams.message = "MailGun request failed (unexpected). ";
					break;

					case 404:
						errorParams.type    = "resourcenotfound";
						errorParams.message = "MailGun requested resource not found (404). This might be caused by an invalid domain or incorrectly programmed API call. ";
					break;

					case 500: case 502: case 503: case 504:
						errorParams.type    = "servererror";
						errorParams.message = "An unexpected error occurred on the MailGun server. ";
					break;

					default:
						errorParams.type    = "unexpected";
						errorParams.message = "An unexpted response was returned from the MailGun server. ";

				}

				try {
					deserialized = DeserializeJson( arguments.fileContent );
				} catch ( any e ){}

				if ( IsStruct( deserialized ) and StructKeyExists( deserialized, "message" ) ) {
					errorParams.message &= "[" & deserialized.message & "]";
				} else {
					errorParams.message &= "MailGun response body: [#arguments.filecontent#]"
				}

				if ( Val( arguments.status_code ) ) {
					errorParams.errorCode = arguments.status_code;
				} else {
					errorParams.errorCode = 500;
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
		<cfargument name="errorcode" type="numeric" required="false" default="500" />

		<cfthrow type      = "cfmailgun.#arguments.type#"
		         message   = "#arguments.message#"
		         errorcode = "#arguments.errorCode#" />
	</cffunction>

	<cffunction name="_dateFormat" access="public" returntype="any" output="false">
		<cfargument name="theDate" type="date" required="true" />

		<cfscript>
			var gmtDate = DateAdd( "s", GetTimeZoneInfo().UTCTotalOffset, theDate );

			return DateFormat( gmtDate, "ddd, dd mmm yyyy" ) & " " & TimeFormat( gmtDate, "HH:mm:ss")  & " GMT";
		</cfscript>
	</cffunction>

	<cffunction name="_boolFormat" access="public" returntype="string" output="false">
		<cfargument name="bool" type="boolean" required="true" />

		<cfreturn arguments.bool ? "yes" : "no" />
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