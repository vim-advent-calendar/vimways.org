css: main.css
	echo 'get main.css...'
	wget https://vimways.org/sass/main.css

title:
	echo 'add H1 to each file'
	sh add_title.sh

title_mac:
	echo 'add H1 to each file'
	sh add_title.sh

epub: main.css
	echo 'create epub'
	pandoc --css main.css -o vimways.epub title.yaml $(grep "publishDate" *md | sed 's/"//g;s/2018-12-//' | sort -t: -nk3 | cut -d: -f1  )

