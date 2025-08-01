#!/usr/bin/bash
exit_status=1;
TERRAFORM="$(which terraform)";
JQ="$(which jq)";
GCLOUD="$(which gcloud)";
if [ $# == 1 ]; then
${TERRAFROM} init >& /dev/null;
${TERRAFROM} apply var="project_filter=$1}" >& /dev/null;
project_list=$(${TERRAFORM} output -json project_info | ${JQ} '.[].project');
for project in ${project_list}
do
    project="${project#*\"}";
    project="${project%\"*}";
    echo "${GCLOUD} projects delete ${project} --quiet";
    exit_status=$?;
    ${TERRAFROM} destroy >& /dev/null;
done;
else
    echo "[FATAL] A project filter string is required" 1>&2;
fi;
exit ${exit_status}
