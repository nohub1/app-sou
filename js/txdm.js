javascript:void(function() {
	try {
		var elms = document.getElementsByClassName("app-guiding-download");
		for (var i = 0; i < elms.length; i++) {
            elms[i].parentNode.removeChild(elms[i]);    
        }
	} catch(e) {
		alert(e.toString());
	}
}())