#!/bin/bash
# test/src/morphology/generate-adverb-lemmas.sh.  Generated from generate-adverb-lemmas.sh.in by configure.

# Automake interprets the exit status as follows:
# - an exit status of 0 will denote a success
# - an exit status of 77 a skipped test
# - an exit status of 99 a hard error
# - any other exit status will denote a failure.

# To run this test script only, do:
#
# make check TESTS=generate-adverb-lemmas.sh

# This test script will test that all verb lemmas do generate as themselves.
# Extend as needed, and copy to new files to adapt to other parts of speech.
# The changes usually needed are:
#
# 1. change the reference to the source file (line 23)
# 2. extend the extract lemmas egrep expression (lines 53 ff)
# 3. adapt the tag addition and lemma generation instructions (lines 79 ff)

###### Variables: #######
POS=adverbs
### in ###
source_file=${srcdir}/../../../src/fst/stems/${POS}.lexc
generator_file=./../../../src/generator-gt-norm

### out ###
padv_lemmas=filtered_p-${POS}
cadv_lemmas=filtered_c-${POS}
sadv_lemmas=filtered_s-${POS}
all_adv=all_${POS}
generated_lemmas=generated-${POS}
result_file=missing_${POS}_lemmas


# FAIL if source file does not exist:
if [ ! -f $source_file ]; then
    echo
    echo "*** Warning: Source file $source_file not found."
    echo
    exit 77
fi

# Use autotools mechanisms to only run the configured fst types in the tests:
fsttype=
fsttype="$fsttype hfst"
#fsttype="$fsttype xfst"

# Exit if both hfst and xerox have been shut off:
if test -z "$fsttype" ; then
    echo "All transducer types have been shut off at configure time."
    echo "Nothing to test. Skipping."
    exit 77
fi

# Get external Mac editor for viewing failed results from configure:
EXTEDITOR=

##### Extract lemmas - extend the egrep exclude pattern in the #####
##### parenthesis as needed to exclude unwanted lexc lines:    #####

# Hent ut lemmaer, bortsett fra Err/Lex (som blir filtrert bort fra normgenerator),
# og lemmaer som som krever Px eller kompareringstagg) . Lemmaene lagres som filtered_p-adverbs
/Users/tpi006/github/giellalt/lang-sme/./../giella-core/scripts/extract-lemmas.sh \
    --exclude "(-comp| LE|-sup |SUP| Px|NOTLEMMA)" \
    $source_file > $padv_lemmas

# Hent ut lemmaer som krever Comp-tag. Lagres som filtered_c-adverbs (se bz 1926)
/Users/tpi006/github/giellalt/lang-sme/./../giella-core/scripts/extract-lemmas.sh \
    --exclude "(-sup |SUP| Px|NOTLEMMA)" \
    --include "(-comp| LE)" \
    $source_file > $cadv_lemmas

# Hent ut lemmaer som krever Superl-tag. Lagres som filtered_s-adverbs(se bz 1926)
/Users/tpi006/github/giellalt/lang-sme/./../giella-core/scripts/extract-lemmas.sh \
    --exclude "( Px|NOTLEMMA)" \
    --include "(-sup |SUP)" \
    $source_file > $sadv_lemmas

###### Start testing: #######
transducer_found=0
Fail=0

# The script tests both Xerox and Hfst transducers if available:
for f in $fsttype; do
	if [ $f == "xfst" ]; then
        lookup_tool="false -flags mbTT"
        suffix="xfst"
        # Does lookup support -q / quiet mode?
        lookup_quiet=$($lookup_tool -q 2>&1 | grep USAGES)
        if ! [[ $lookup_quiet == *"USAGES"* ]] ; then
            # it does support quiet mode, add the -q flag:
            lookup_tool="false -q -flags mbTT"
        fi
	elif [ $f == "hfst" ]; then
		lookup_tool="/usr/local/bin/hfst-lookup -q"
		suffix="hfstol"
	else
	    Fail=1
		printf "ERROR: Unknown fst type! "
	    echo "$f - FAIL"
	    continue
	fi
	if [ -f "$generator_file.$suffix" ]; then
		let "transducer_found += 1"

###### Test generation: #######
		# generate adverbs, extract the resulting generated lemma,
		# store it:

# Generer adverbformen av lemmaene i adverbs
sed 's/$/+Adv/' $padv_lemmas | $lookup_tool $generator_file.$suffix | \
    cut -f2 | grep -v "Adv+" | grep -v "^$" > $generated_lemmas.$f.txt  

# Generer adverbformen av lemmaene i compadverbs med +Adv+Comp (se bz 1926)
sed 's/$/+Adv+Comp/' $cadv_lemmas | $lookup_tool $generator_file.$suffix | \
    cut -f2 | grep -v "Adv+" | grep -v "^$" >> $generated_lemmas.$f.txt  

# Generer adverbformen av lemmaene i supadverbs med +Adv+Superl (se bz 1926)
sed 's/$/+Adv+Superl/' $sadv_lemmas | $lookup_tool $generator_file.$suffix | \
    cut -f2 | grep -v "Adv+" | grep -v "^$" >> $generated_lemmas.$f.txt  


###### Collect results: #######
		# Sort and compare original input with resulting output - the diff is
		# stored and opened in SEE:
		
# Sorter og unifiser
sort -u -o $generated_lemmas.$f.txt $generated_lemmas.$f.txt

# Alle adverblemmaer samles i ei fil
cat $padv_lemmas $cadv_lemmas $sadv_lemmas | sort -u > $all_adv


# Sammenlikne lista med adverblemmaer med den genererte lista med adverber.
#Adverblemmaer som ikke er i den genererte lista, kopieres til missing_adverb_lemmas.txt.
# Formene generes med  +Adv for enklere debugging. 

		comm -23 $all_adv $generated_lemmas.$f.txt \
		     | grep -v '^$' | sed 's/$/+Adv/' \
		     | $lookup_tool $generator_file.$suffix > $result_file.$f.txt

		# Open the diff file in SubEthaEdit (if there is a diff):
		if [ -s $result_file.$f.txt ]; then
			# Only open the failed lemmas in see if  is defined:
			if [ "$EXTEDITOR" ]; then
				$EXTEDITOR $result_file.$f.txt
			fi
		    Fail=1
		    echo "$f - FAIL"
		    continue
		fi
	    echo "$f - PASS"
	fi
done

# When done, remove the generated data file:
rm -f $padv_lemmas $cadv_lemmas $sadv_lemmas $all_adv $generated_lemmas.$f.txt

# At least one of the Xerox or HFST tests failed:
if [ "$Fail" = "1" ]; then
	exit 1
fi

if [ $transducer_found -eq 0 ]; then
    echo ERROR: No transducer found
    exit 77
fi
