IFS=$'\n'
for l in $(grep "^title" *md | cut -d: -f 1,3)
    do
        file=${l%:*}
        title=$(echo ${l#*: } | sed s/\"//g)
        echo $title,$file
        sed -i.back '0,/^---/! s/^---$/---\n\n# '$title'/' $file
done
