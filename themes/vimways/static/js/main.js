document.addEventListener("DOMContentLoaded", function() {
	var navigators = document.querySelectorAll('.navigator');

	for (var i = 0; i < navigators.length; i++) {
		navigators[i].addEventListener('change', function() {
			window.location.href = this.elements[0].value;
		}, false);
	}
}, false);
