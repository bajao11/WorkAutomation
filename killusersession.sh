#!/bin/sh
#echo "You chose $Region"

ORACLE_HOME=/home/jenkins/oracle/instantclient_12_2
export ORACLE_HOME
ORACLE_SID=ORA_CLIENT_JENKINS
TNS_ADMIN="$ORACLE_HOME"
export TNS_ADMIN
PATH=$PATH:$ORACLE_HOME:$ORACLE_HOME/OPatch:.
export PATH
LD_LIBRARY_PATH=$ORACLE_HOME:$ORACLE_HOME/jdk/jre/lib/amd64:$ORACLE_HOME/jdk
export LD_LIBRARY_PATH


sendtoslack(){

outname="Kill Database User Sessions"
myemoji=":database:"
text_out="Database User Sessions Killed in Test $Region Environment. Please proceed with the release."
#channel="sb-oncall-alerts"
#tokenhk=""
channel="webhook_tests"
tokenhk="https://hooks.slack.com/services/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"
curl -X POST --data-urlencode "payload={\"channel\": \"#${channel}\", \"username\": \"${outname}\", \"text\": \"${text_out}\", \"icon_emoji\": \"${myemoji}\"}" ${tokenhk}

}

killsession(){
/home/jenkins/oracle/instantclient_12_2/sqlplus -s -L JENKINS_TIBCO/$PASS@$ServiceName << EOF
SET PAGESIZE 1000 LINESIZE 500 TRIMS ON TAB OFF FEEDBACK OFF HEADING OFF
set serveroutput on;
declare
sesscnt number;
begin
for i in 1..10 loop
SELECT count(1) into sesscnt FROM gv\$session where status = 'ACTIVE' and username not in ('UTILITY','SB-FOGLIGHTADMIN','SYS','JENKINS_TIBCO') and type != 'BACKGROUND';
    if sesscnt < 1 then
        dbms_output.put_line('Session Count: ' || sesscnt);
        exit;
    else
		UTILITY.KILL_ALL_SB_SESSIONS;
        dbms_output.put_line('Session Count: ' || sesscnt);
        dbms_lock.sleep(2);
    end if;
end loop;
end;
/
SELECT sid,serial#,inst_id,username,machine FROM gv\$session where status = 'ACTIVE' and username not in ('UTILITY','SB-FOGLIGHTADMIN','SYS','JENKINS_TIBCO') and type != 'BACKGROUND';
exit;
EOF
}

if [ $SYSTEM_STOPPED == 'false' ]
then
  echo "Please execute system_stop.sh first before to proceed with kill session"
  exit 1
else
  echo "system_stop.sh has been executed. Proceed with the kill session"
  if [ $Region == 'Test-AP' ]
  then
    ServiceName="QSBCH"
  elif [ $Region == 'Test-EU' ]
  then
    ServiceName="QSBEU"
  else
    ServiceName="QSBAM"
  fi

  echo "You chose $Region , The ServiceName is $ServiceName"
  killsession

  sendtoslack
fi
