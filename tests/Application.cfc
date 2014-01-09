component output=false {
	this.name = "cfmailguntests_" & ExpandPath( "/" );

	path = GetDirectoryFromPath( GetCurrentTemplatePath() );

	this.mappings[ "/tests" ]     = path;
	this.mappings[ "/cfmailgun" ] = path & "/../";

	function onRequest( target ){
		include template=target;
	}
}