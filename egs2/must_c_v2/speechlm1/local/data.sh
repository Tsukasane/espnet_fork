#!/usr/bin/env bash
# Set bash to 'debug' mode, it will exit on :
# -e 'error', -u 'undefined variable', -o ... 'error in pipeline', -x 'print commands',
# set -e
# set -u
# set -o pipefail

. ./db.sh || exit 1;
. ./path.sh || exit 1;
. ./cmd.sh || exit 1;

log() {
    local fname=${BASH_SOURCE[1]##*/}
    echo -e "$(date '+%Y-%m-%dT%H:%M:%S') (${fname}:${BASH_LINENO[0]}:${FUNCNAME[1]}) $*"
}
SECONDS=0

stage=1
stop_stage=100000

lang=$1
task=$2

log "$0 $*"

if [ -z "${MUST_C}" ]; then
    log "Fill the value of 'MUST_C' of db.sh"
    exit 1
fi

# check extra module installation
if ! command -v tokenizer.perl > /dev/null; then
    echo "Error: it seems that moses is not installed." >&2
    echo "Error: please install moses as follows." >&2
    echo "Error: cd ${MAIN_ROOT}/tools && make moses.done" >&2
    return 1
fi

if [ $# -ne 2 ]; then
    log "Error: lang argument is required."
    exit 2
fi

if [ ${stage} -le 1 ] && [ ${stop_stage} -ge 1 ]; then
    log "stage 1: Data Download"
    mkdir -p ${MUST_C}
    local/download_and_untar.sh ${MUST_C} ${lang} "v2"
fi

if [ ${stage} -le 2 ] && [ ${stop_stage} -ge 2 ]; then
    local/data_prep.sh ${MUST_C} ${lang} "v2"
    for set in train dev tst-COMMON tst-HE; do
        if [ ${task} == "mt" ] ; then
            cp data/${set}.en-${lang}/text.tc.en data/${set}.en-${lang}/src_text
        else
            cp data/${set}.en-${lang}/text.lc.rm.en data/${set}.en-${lang}/src_text
        fi
        cp data/${set}.en-${lang}/text.tc.de data/${set}.en-${lang}/text
    done
fi
log "Successfully finished. [elapsed=${SECONDS}s]"
