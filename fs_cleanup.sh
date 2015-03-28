#!/bin/bash

#for i in `ls` ; do touch $i/${i}-file4 ; done


# path's must be on the same filesystem (separate by space)
	path_to_clean="/root/_projects/fs_cleanup/bla1 /root/_projects/fs_cleanup/bla2"
# mountpoint of the filesystem, where the above paths live
	mountpoint="/"

# size in %, when we should start our cleaner
	cleansize="30%"
# maximum files to be deleted in one run
	max_files="2"




######## code from here
	#debug me ? 
	debug=1

   # functions
	# debugging
	function debug {
		echo -e " -debug-> $1 \t\t$2"
	}


	# get file system usage in %
	t_used=`df $mountpoint |  awk '{ print $5 }' | tail -n 1`
		debug "$t_used $cleansize" "Size_used,Size_start"

	# trim the vars
	t_used=`echo $t_used | cut -d '%' -f 1`
	cleansize=`echo $cleansize | cut -d '%' -f 1`
		debug "$t_used $cleansize" "trimmed - Size_used,Size_start"

	# check if we need to run
	if [ $t_used -lt $cleansize ] ; then
		echo "we do not need to start, Fee Space is at $t_used%, we start at $cleansize%"
		exit 1
	else
		debug "starting with $t_used% (startsize is $cleansize%)"
	fi


	# get oldest files from dirs
		debug "checking dir: $t_dir"
		if [ $max_files -eq 0 ] ; then
			t_head=""
			debug "no max_files set"
		else
			t_head="| head -n $max_files"
			debug "setting max_files to $max_files"
		fi
		find $path_to_clean -type f -print0 | xargs -0 ls -ltr --time-style=+"%Y%m%d%H%M%S" | awk '{print $6,$7}' | sort -n $t_head

exit 0
