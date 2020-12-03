#!/bin/bash

# Determine Maven goal
# Behaviour can be overridden by exporting the MVN_GOAL variable
if [ ! -z "${MVN_GOAL}" ]
then
	echo "Using goal from MVN_GOAL variable: ${MVN_GOAL}"
else
	#by default, use "install"
    MVN_GOAL="install"
    
	#check if nexus credentials are set
    if [ -z "${NEXUS_DEPLOY_USERNAME}" ] || [ -z "${NEXUS_DEPLOY_PASSWORD}" ]
    then
        echo "Nexus credentials not set. Skipping Maven deployment!"
    else
    	#if snapshot OR tag, deploy
    	if [ ! -z "${TRAVIS_TAG}" ] || (grep "<version>" pom.xml|head -n1 | egrep -q "<version>.*SNAPSHOT</version>")
    	then
	        MVN_GOAL="deploy"	
	    else
	    	echo "Not a snapshot release or tagged revision. Skipping Maven deployment!"
	    fi
    fi
fi
mvn ${MVN_GOAL} $@
