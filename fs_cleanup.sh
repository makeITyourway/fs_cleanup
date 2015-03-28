#!/bin/bash

#for i in `ls` ; do touch $i/${i}-file4 ; done

# REALLY DELETE FILES OR JUST SHOW WHAT I WOULD HAVE DONE (1) do nothing (0) delte !!!
	dry_run=1
# path's must be on the same filesystem (separate by space)
	path_to_clean="/root/_projects/fs_cleanup/bla1 /root/_projects/fs_cleanup/bla2"
# mountpoint of the filesystem, where the above paths live
	mountpoint="/"
# delte files(f) or directorys(d)   (keep in mind setting the max_files corrsponding to the delete_type, files might need bigger max_files than dir"
	deletetype="d"
# size in %, when we should start our cleaner
	cleansize="30%"
# maximum files to be deleted in one run (0) unlimited
	max_files="0"
# RM - Options - you should not have to modify them
	rm_opts="-fr"



######## code from here
	#debug me ? 
	debug=0

   # functions
	# debugging
	function debug {
		if [ "$debug" -eq "1" ] ; then 
			echo -e " -debug-> $1 \t\t$2"
		fi
	}

	# get file system usage in %
	t_used=`df $mountpoint |  awk '{ print $5 }' | tail -n 1  | cut -d '%' -f 1`
		debug "$t_used $cleansize" "Size_used,Size_start"

	# trim the vars
	cleansize=`echo $cleansize | cut -d '%' -f 1`
		debug "$t_used $cleansize" "trimmed - Size_used,Size_start"

	# check if we need to run
	if [ $t_used -lt $cleansize ] ; then
		echo "we do not need to start, Fee Space is at $t_used%, we start at $cleansize%"
		exit 1
	else
		debug "starting with $t_used% (startsize is $cleansize%)"
	fi


	# set an emergency limit
	emergency_limit=200
	# get oldest files from dirs
		debug "checking dir: $t_dir"
		if [ $max_files -eq 0 ] ; then
			debug "no max_files set"
			result=`find $path_to_clean -type $deletetype -print0 | xargs -0 stat --format='%X;%n' | sort -n | head -n $emergency_limit`
			max_files=$emergency_limit
		else
			debug "setting max_files to $max_files"
			result=`find $path_to_clean -type $deletetype -print0 | xargs -0 stat --format='%X;%n' | sort -n | head -n $max_files`
		fi
			debug "Result (latest files):\n##\n$result\n##" "\nfinished results"

		# calculate num results to make a hard break	
		num_results=`echo $result | wc -l`
		num_results=$[$num_results+1]
			debug "result file has $num_results lines"
			
		# now starting the deletion loop

		t_max_files=1
		#while [ $t_used -ge $cleansize ] && [ $t_max_files -le $max_files ] && [ $t_max_files -le 2 ] && [ $t_max_files -le $num_results ]; do
		while [ $t_used -ge $cleansize ] && [ $t_max_files -le $max_files ] && [ $t_max_files -le 5 ] && [ $t_max_files -le $num_results ] ; do
			
#			for t_line in $result ; do
				t_line=`echo $result | head -n $t_max_files | tail -n 1` 
				debug "fileline: $t_line"
				t_2delfiledate=`echo $t_line | cut -d ";" -f 1` 	
				t_2delfiledate=`date -d @$t_2delfiledate`
				t_2delfilename=`echo $t_line | cut -d ";" -f 2` 	
				if [ "$dry_run" == "delete" ] ; then
					echo "-deleted-> $t_2delfilename ($t_2delfiledate)"
					rm $rm_opts $t_2delfilename
				else
					echo "-dry_run-> $t_2delfilename ($t_2delfiledate)"
				fi
				

				#cout up deleted files
				echo $t_max_files
				t_max_files=$[$t_max_files+1]

				# get new disk space
				t_used=`df $mountpoint |  awk '{ print $5 }' | tail -n 1 | cut -d '%' -f 1`
		done
exit 0
