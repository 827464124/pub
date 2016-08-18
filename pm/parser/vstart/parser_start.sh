#!/bin/bash
#set -x
#-------------------------------------------------------------------------------
# @(#) common-modules/Parser_Main/nprparser_start.sh common-modules_r2.1.3.2:cset.000804:5:5 11/30/00 @(#)
#-------------------------------------------------------------------------------
#
# The following environment variables should be customised to
# reflect the locations of the respective subjects.
BASE_DIR=.
PERL5=/usr/bin/perl

SPOOL_DIR=/ioss/spool
PM_DIR=/ioss/pm
LOG_DIR=/ioss/log

PARSER_HOME=${PM_DIR}/parser

AUDIT_FILE=${LOG_DIR}/snmp_parse.audit
LOG_FILE=${LOG_DIR}/snmp_parse.log
LOG_LEVEL=5


DATA_DIR=${SPOOL_DIR}
IN_DIR=${DATA_DIR}/raw
INT_DIR=${DATA_DIR}/intermediate
OUT_DIR=${DATA_DIR}/load

INPUT_STORAGE_DIR=${DATA_DIR}/archive
INTERMEDIATE_STORAGE_DIR=#${DATA_DIR}/intermediate
OUTPUT_STORAGE_DIR=#${DATA_DIR}/load

# To configure parser utility , set PARSE_COUNT to path of $NPR_DIR
PARSE_COUNT=0

# Enter the max size (in bytes) for loader (OUT_DIR) directory, or enter 0 to leave unlimited size
LOADER_SIZE=0

DEBUG=nodebug
OLD_AGE=0


#--------------------------------------
# Check directories first
#

if [ ! -d ${IN_DIR} ]
then
    echo "${IN_DIR} is incorrect"
    exit 2
fi
if [ ! -d ${INT_DIR} ]
then
    echo "${INT_DIR} is incorrect"
    exit 2
fi
if [ ! -d ${OUT_DIR} ]
then
    echo "${OUT_DIR} is incorrect"
    exit 2
fi

RELEASE=vstart
#-------------------------------------------------------------------------------
# Changing directory to the directory in the parser tree where
# the configuration files for this parser reside.
cd ${PARSER_HOME}/${RELEASE}

${PERL5} -I${PARSER_HOME}/parsersrc\
	-I${PARSER_HOME}/${RELEASE} \
	${PARSER_HOME}/parsersrc/parser_main.pm\
	--audit_file=${AUDIT_FILE} \
	--log_file=${LOG_FILE} \
	--log_level=${LOG_LEVEL} \
	--input_directory=${IN_DIR} \
	--intermediate_directory=${INT_DIR} \
	--output_directory=${OUT_DIR} \
	--parser_directory=${PARSER_HOME} \
	--name="SNMP Parser" \
	--input_storage_dir=${INPUT_STORAGE_DIR} \
	--intermediate_storage_dir=${INTERMEDIATE_STORAGE_DIR} \
	--output_storage_dir=${OUTPUT_STORAGE_DIR} \
	--parse_count=${PARSE_COUNT} \
        --loader_size=${LOADER_SIZE} \
	--${DEBUG} >> ${LOG_FILE} 2>&1;



