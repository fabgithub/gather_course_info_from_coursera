
coursera_url="https://www.coursera.org"
browse_url="$coursera_url/browse"
language="_facet_changed_=true&primaryLanguages=en%2Czh-CN%2Czh-TW"

res=

get_list_from_url()
{
	out_file=$1
	url=$2
	sep=$3

	if [ -f $out_file ]; then
		echo "$out_file exist, use it."
	else
		curl -o $out_file "$url" || (echo fail download file $out_file && exit 1)
	fi
	res=`cat $out_file | grep "$sep" | awk -F "$sep" '{for(i = 2;i <= NF;++i) print $i}' | awk -F '"' '{print $1}'`
}

get_and_parse_course_page()
{
	local course_list_file=$1
	local specializations_file=$2
	local courses_file=$3

	# course_list_file="$sub_dir/$sub-page_$p.html"
	echo "process couse list file " "$course_list_file"
	get_list_from_url $course_list_file "$browse_url/$cate/$sub?$language&page=$p" 'https://www.coursera.org/specializations/'
	page=$res
	if [ "$res" != "" ]; then
		local spec_courses_dir=`dirname $specializations_file`/specializations
		if [ ! -d $spec_courses_dir ]; then
			mkdir $spec_courses_dir
		fi
		for c in $page; do
			echo "/specializations/$c" >> $specializations_file
			echo "get course list for specializations $c from file $course_list_file"
			get_list_from_url "$spec_courses_dir/$c.html" "$coursera_url/specializations/$c" 'https://www.coursera.org/learn/'
			local courses=$res
			for c in $courses; do
				echo "/learn/$c"
			done
			echo
		done
		echo
	fi
	get_list_from_url $course_list_file "$browse_url/$cate/$sub?$language&page=$p" 'https://www.coursera.org/learn/'
	local page=$res
	for c in $page; do
		echo "/learn/$c" >> $courses_file
	done
	echo
}

get_list_from_url 'browse.html' $browse_url 'data-track-href="/browse/'
categories=$res
echo $categories

if [ ! -d browse ]; then
	mkdir browse
fi

for cate in $categories; do
	cate_dir=browse/$cate
	if [ ! -d $cate_dir ]; then
		mkdir $cate_dir
	fi
	get_list_from_url "$cate_dir.html" $browse_url/$cate ' to="#'
	sub_categories=$res
	echo $sub_categories
	echo 

	a=($res)
	sub_count=${#a[@]}
	if [ 0 == $sub_count ]; then
		echo "&&&&&&&&&&&& no sub categories &&&&&&&&&&&&&&"
		specializations_file="$cate_dir/$cate"_specializations.txt
		courses_file="$cate_dir/$cate"_courses.txt
		course_list_file="$cate_dir.html"
		get_and_parse_course_page "$course_list_file"  "$specializations_file" "$courses_file"
		continue
	fi

	for sub in $sub_categories; do
		sub_dir=$cate_dir/$sub
		if [ ! -d $sub_dir ]; then
			mkdir $sub_dir
		fi
		get_list_from_url "$sub_dir.html" "$browse_url/$cate/$sub?$language" '&amp;page='
		a=($res)
		page_count=${#a[@]}
		if [ $page_count == 0 ]; then
			echo no page
		else
			page_count=${a[$page_count - 2]}
			# page_count=$res
			echo $res
			echo $page_count "*******"
		fi
		echo

		specializations_file="$sub_dir/$cate"_"$sub"_specializations.txt
		courses_file="$sub_dir/$cate"_"$sub"_courses.txt


		echo "" > $specializations_file
		echo "" > $courses_file

		for ((p=1;p<=$page_count;p++)); do
			course_list_file="$sub_dir/$sub-page_$p.html"
			get_and_parse_course_page "$course_list_file" "$specializations_file" "$courses_file"
		done
	done
done
