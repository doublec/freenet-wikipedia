#! /bin/bash
if [ ! -d "out" ]; then
  echo "Directory 'out' does not exist."
  exit 1
fi

if [ -d "result" ]; then
  echo "Directory 'result' already exists."
  exit 1
fi

prefix="1,2,3"

rm -rf result
mkdir -presult 
mkdir -p result/html/I
cp -r "out/-" "out/M" result/html/
cp -r "out/I/favicon.png" "out/I/s" result/html/I

read -r -d '' b <<'EOF'
<div style="width:800px; margin: 0 auto; clear:both; background-image:linear-gradient(180deg, #E8E8E8, white); border-top: dashed 2px #AAAAAA; padding: 0.5em 0.5em 2em 0.5em; margin-top: 1em; direction: ltr;"><a href="../../index.html">This snapshot</a> was generated and distributed by a third party for the <a href ="https://freenetproject.org/">Freenet project</a> and is not associated with Wikipedia in any way. It was created from the <a href="http://wiki.kiwix.org/wiki/Content_in_all_languages">kiwix ZIM file</a>.</div>
EOF
js='<script src="../-/j/body.js"></script>'

# Copy images
for f in out/I/m/*; do
 base=$(basename "$f")
 dir1=$(echo "$base"|sha256sum|awk '{ print $1 }'|cut -c "$prefix")
 destname=$(echo "$base"|iconv -f utf-8 -t ascii//translit|sed 's/\?/X/g')
 mkdir -p result/images/"$dir1"
 cp "$f" result/images/"$dir1"/"$destname"
 echo "$dir1"/"$base"
done

# Copy html
for f in out/A/*.htm*; do
 base=$(basename "$f")
 dir1=$(echo "$base"|sha256sum|awk '{ print $1 }'|cut -c "$prefix")
 destname=$(echo "$base"|iconv -f utf-8 -t ascii//translit|sed 's/\?/X/g')
 mkdir -p result/html/"$dir1"
 find="$js" body="$b" perl -pe 's/<meta>//g;' -pe 's/<meta (property|id)[^>]*>//g;' -pe "s/\$ENV{find}/\$ENV{body}/g;" "$f" >result/html/"$dir1"/"$destname"
 echo "$dir1"/"$base"
done

# Update image links
find result/html -name "*.htm*" -print |sort| while read f; do
  cmd=""
  echo file: "$f"
#  echo Images:
  images=$(grep -Eoi 'src="\.\.\/I\/m\/[^\"]+' "$f"|cut -c "6-")
  for i in $images; do
    decoded=$(echo "$i"|sed 's@+@ @g;s@%@\\x@g' | xargs -0 printf "%b")
    translated=$(echo "$decoded"|iconv -f utf-8 -t ascii//translit|sed 's/\?/X/g')
#    echo "   : $i"
    basedecoded=$(basename "$decoded")
    baseencoded=$(basename "$i")
    basetranslated=$(basename "$translated")
    dir1=$(echo "$basedecoded"|sha256sum|awk '{ print $1 }'|cut -c "1,2,3")
    newurl="../../images/$dir1/$basetranslated"
    cmd="$cmd -pe s|\Q$i\E|$newurl|g;"
#    a="$i" b="$newurl" perl -i -pe "s/\$ENV{a}/\$ENV{b}/g" "$f"
  done 
  if [[ ! -z $cmd ]]; then
    perl -i $cmd "$f"
  fi
done

# Update html links
find result/html -name "*.htm*" -print |sort| while read f; do
  cmd=""
  echo file: "$f"
#  echo Links:
  href=$(grep -Eoi 'href="[^\"]+' "$f"|cut -c "7-"|grep -Ev '(^http|^https|^\.|^\/)')
  for i in $href; do
    decoded=$(echo "$i"|sed 's@+@ @g;s@%@\\x@g' | xargs -0 printf "%b")
    translated=$(echo "$decoded"|iconv -f utf-8 -t ascii//translit|sed 's/\?/X/g')
#    echo "   : $i"
    basedecoded=$(basename "$decoded")
    baseencoded=$(basename "$i")
    basetranslated=$(basename "$translated")
    dir1=$(echo "$basedecoded"|sha256sum|awk '{ print $1 }'|cut -c "1,2,3")
    newurl="../$dir1/$basetranslated"
    cmd="$cmd -pe s|\Q\"$i\E|\"$newurl|g;"
#    a="$i" b="$newurl" perl -i -pe "s/\$ENV{a}/\$ENV{b}/g" "$f"
  done 
  if [[ ! -z $cmd ]]; then
    perl -i $cmd "$f"
  fi
done

# Update index
cp `find result -name "index.htm"` result/index.html
sed -i -e 's/..\/..\/index.html/index.html/g' -e 's/..\/..\/images/images/g' -e 's/..\/\-/html\/\-/g' -e 's/href="..\//href="html\//g' result/index.html
