#!/bin/bash

#for i in `ls` ; do touch $i/${i}-file4 ; done

# REALLY DELETE FILES OR JUST SHOW WHAT I WOULD HAVE DONE (1) do nothing (no0) delte !!!
	dry_run=1
# path's must be on the same filesystem (separate by space) 
	#/!\ ATTENTION /!\ - finish every dir with a trailing * - otherwise your root dir will be deleted - never use your root system !
	#example: 	path_to_clean="/files/bla1/* /files/bla2/*"
	path_to_clean="/files/0-9/* /files/A/*"
# mountpoint of the filesystem, where the above paths live - your root system is not a good idea !!!
	mountpoint="/files/"
# delte files(f) or directorys(d)   (keep in mind setting the max_files corrsponding to the delete_type, files might need bigger max_files than dir"
	deletetype="f"
# size in %, when we should start our cleaner
	cleansize="90%"
# maximum files to be deleted in one run (0) unlimited
	max_files="3"
# RM - Options - you should not have to modify them
	rm_opts="-fr"



######## code from here
	#debug me ? 
	debug=0


   #re flight checks

	mountreal=`mount | grep $mountpoint` 
	if [ -z "$mountreal" ] ; then
		echo "ERROR: you have entered an invalid mountpoint at ::mountpoint"
#		exit 1
	fi


# removed due to error in script due to the trailing *
#	for t_dir in $path_to_clean ; do
#		#t_dir=`echo $t_dir | cut -d "*" -f 1`
#		t_dir=`dirname $t_dir`	
#		echo $t_dir
#		if [ ! -d "$t_dir"  ] ; then
#			echo "ERROR: you have entered an invalid dir to scan for files ::path_to_clean:: --> $dir"
#			exit 1
#		fi
#	done
	

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
		echo "INFORMATION: there is no need to delete files, Free Space is at $t_used%, we start deletion at $cleansize%"
		exit 1
	else
		debug "starting with $t_used% (startsize is $cleansize%)"
	fi


	# set an emergency limit
	emergency_limit=1000

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
		num_results=`echo "$result" | wc -l`

		if [ -z $result ] ; then
			echo "ERROR: we could not find anything to delete"
		fi 	
		num_results=$[$num_results+1]
			debug "result file has $num_results lines"
			
		# now starting the deletion loop

		t_max_files=1
		#while [ $t_used -ge $cleansize ] && [ $t_max_files -le $max_files ] && [ $t_max_files -le 2 ] && [ $t_max_files -le $num_results ]; do
		while [ $t_used -ge $cleansize ] && [ $t_max_files -le $max_files ] && [ $t_max_files -le $emergency_limit ] && [ $t_max_files -le $num_results ] ; do
	
				t_line=`echo "$result" | head -n $t_max_files | tail -n 1` 
					debug "fileline: $t_line"
				# grep file and date from line 
				t_2delfiledate=`echo $t_line | cut -d ";" -f 1` 	
				t_2delfiledate=`date -d @$t_2delfiledate`
				t_2delfilename=`echo $t_line | cut -d ";" -f 2` 	
				if [ "$dry_run" == "no" ] ; then
					rm $rm_opts $t_2delfilename
					action="-deleted->"
				else
					action="-dry_run->"
				fi


				# get new disk space
				t_used=`df $mountpoint |  awk '{ print $5 }' | tail -n 1 | cut -d '%' -f 1`
				debug "now having a disk_usage of $t_used"

				# giving output to the user
				echo "$action $t_2delfilename ($t_2delfiledate), now having $t_used% free space"
				

				#cout up deleted files
				t_max_files=$[$t_max_files+1]

	done
exit 0
