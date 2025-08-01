#!/usr/bin/bash
GCLOUD=$(which gcloud);
exit_status=1;
ok_to_continue=1;
VALID_OPTIONS="fhnvt:"
major=1;
minor=0;
subversion=0;
project_id="";
region="";
repository_id="";
tfvars_file="";
files_only=1;
declare -A version_info={MAJOR=${major} MINOR=${MINOR} SUBVERSION=${subversion}];
version="${MAJOR}.${MINOR}.${SUBVERSION}";

display_help() {
    echo "clean_repository [h] [n] [t tfvars file] [v] [var1=yyy var2=zzz...]"
    echo "-h - display this message";
    echo "-f - delete files only."
    echo "-n - dryrun";
    echo "-t - tfvars filename";
    echo "-v - version info to stdout".
    echo "Optional variables"
    echo "Required variables are region, project_id and repository_id.";
};
delete_images() {
    local tmp_file;
    local found_entries;
    local local_status=0;
    if [ ${files_only} == 1 ]; then
	tmp_file=$(mktemp);
	${GCLOUD} artifacts docker tags list ${region}-docker.pkg.dev/${project_id}/${repository_id}/  >& "${tmp_file}";
	cat "${tmp_file}";
	found_entries=1;
	while read -a line;
	do
	    if [ "${line[0]}" = "TAG" ]; then
		found_entries=0;
		continue;
	    fi;
	    if [ "${found_entries}" == 0 ]; then
		${GCLOUD} artifacts docker images delete ${line[1]} --delete-tags --quiet;
	    fi;
	done <  "${tmp_file}";
	rm -f "${tmp_file}";
    fi;
    return ${local_status};
}

delete_files() {
   local local_status=0;
   local tmp_file=$(mktemp);
   ${GCLOUD} artifacts files list --location=${region} --project=${project_id} --repository=${repository_id}  >& "${tmp_file}";
   local found_entries=1;
   while read -a line;
   do
      if [ "${line[0]}" = "FILE" ]; then
  	 found_entries=0;
	 continue;
      fi;
      if [ "${found_entries}" == 0 ]; then
         ${GCLOUD} artifacts files delete ${line[0]} --location=${region} --project=${project_id} --repository=${repository_id} --async --quiet;
      fi;
   done <  "${tmp_file}";		
   rm -f "${tmp_file}";
   return ${local_status};
}

if [ -n "${GCLOUD}" ]; then
    exit_status=0;
    while getopts "${VALID_OPTIONS}" cur_opt;
    do
	case ${cur_opt} in
	     h)
	       display_help;
	       exit_status=0;
	       break;
	       ;;
	       v)
		   echo "${MAJOR}.${MINOR}.${SUBVERSION}";
		   ;;
	    \?)
		echo "Invalid option: -$OPTARG" >&2
		exit_status=1
		break
		;;
	    t)
		tfvars_file="$OPTARG";
		;;
	    f)
		files_only=0;
		;;
	   :)
	       echo "Option -$OPTARG requires an argument." >&2
	       exit_status=1
	       break
	       ;;
	       esac;
	done;
    shift $((OPTIND - 1));
    if [ -f "${tfvars_file}" ]; then
	while read -r line;
	do
	    key="${line%% =*}";
	    value="${line##*= }";
	    value="${value%\"}"
	    value="${value#\"}"
	    case "${key}" in
	     "project_id")
		 project_id="${value}";
	     ;;
	     "region_id")
	         region_id="${value}"
		 ;;
	     "repository_id")
	         repository_id="${value}";
		 ;;
	     *)
		 echo "ignoring ${key}";
	     esac;
        done < "${tfvars_file}";	
    fi;
    for cur_arg in "$@"; do
	read -r line <<< "$cur_arg";
	    key="${line%%=*}";
	    value="${line##*=}";
	    value="${value%\"}"
	    value="${value#\"}"
	    case "${key}" in
	     "project_id")
		 project_id="${value}";
	     ;;
	     "region")
	         region="${value}"
		 ;;
	     "repository_id")
	         repository_id="${value}";
		 ;;
	     *)
		 echo "ignoring \"${key}\"";
	     esac;	
    done;
    if ([ -n "${region}" ] && [ -n "${project_id}" ] && [ -n "${repository_id}" ]); then
	ok_to_continue=0;
    fi;
    if [ ${ok_to_continue} == 0 ]; then
	delete_images;
	# Next delete the files.
	delete_files;
    fi;
    
    # gcloud artifacts docker tags list ${var.region}-docker.pkg.dev/${var.project_id}/${var.repository_id}/
else
    echo "[FATAL] gcloud command not found";
fi;
exit ${exit_status};
