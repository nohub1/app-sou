javascript:void(function() {
	try {
		var elms = document.getElementsByClassName("header");
                elms[0].parentNode.removeChild(elms[0]);
		
		try {
			var elm = document.getElementById("top_app_download");
			elm.parentNode.removeChild(elm);
		} catch(e){}
		
		try {
			var elm = document.getElementById("detail_download_bottom");
			elm.parentNode.removeChild(elm);
		} catch(e){}
		
		try {
			var elms = document.getElementsByClassName("fixed-circle");
	                elms[0].parentNode.removeChild(elms[0]);
		} catch(e){}
		
		var elms = document.getElementsByClassName("img-banner");
                elms[0].parentNode.removeChild(elms[0]);
		
		var elms = document.getElementsByClassName("search-form");
                elms[0].parentNode.removeChild(elms[0]);
		
		var elms = document.getElementsByClassName("footer");
                elms[0].parentNode.removeChild(elms[0]);
		
		var elms = document.getElementsByClassName("public-module");
                elms[elms.length - 1].parentNode.removeChild(elms[elms.length - 1]);
	} catch(e) {

	}
}())
