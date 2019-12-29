document.addEventListener("DOMContentLoaded", function() {
	var navigators = document.querySelectorAll('.navigator');

	for (var i = 0; i < navigators.length; i++) {
		navigators[i].addEventListener('change', function() {
			window.location.href = this.elements[0].value;
		}, false);
	}

	if (window.location.pathname === '/2019/') {
		var futures = document.querySelectorAll('.future');
		var container = document.querySelector('.container > .articles');

		var articles = [];

		futures.forEach(function(future){
			var movable = parseInt(future.attributes['data-movable'].value, 10);
			if (movable > 0 && movable <= 5) {
				articles.push(future);
			}
			if (movable > 5 && movable < 25) {
				future.parentNode.removeChild(future);
			}
		});

		articles.forEach(function(article) {
			article.querySelector('.month-year').innerHTML = 'January';
			container.appendChild(article);
		});
	}
}, false);
