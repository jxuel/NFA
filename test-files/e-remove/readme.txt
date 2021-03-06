This directory contains test files for the epsilon-transition removal
portion of the CSCE 355 programming project.  Below is a list of the
files in this directory with a description of each, including how it
was generated.

Files with names of the form test-e-NFA#-output.txt, where # is a hex
digit, are generated by running the executable solution on the
corresponding test file, i.e., by the shell command
    $ e-remove test-e-NFA#.txt > test-e-NFA#-output.txt

There are two executables available: e-remove-linux, which runs on
a Linux machine, and e-remove-mac, which runs on an Apple Mac.

---------------

test-e-NFA1.txt - The example e-NFA depicted in the handout.
    Hand-edited.

test-e-NFA2.txt - An 8-state e-NFA with a long chain of epsilon-moves.
    Hand-edited.

test-e-NFA3.txt - An 8-state e-NFA similar to test-e-NFA2.txt.
    Hand-edited.

test-e-NFA4.txt - A randomly generated e-NFA with 10 states and
    alphabet size 2.
    Generated by the shell command
        $ makeRandomNFA.pl 1357 10 2 0.2 0.1 0.05 > test-e-NFA5.txt
    then hand-edited to remove the two self-loops at state 0.
    (Run makeRandomNFA.pl with no arguments to get usage info.)

test-e-NFA5.txt - A randomly generated e-NFA with the max number of
    states (64) and the max alphabet size (26).
    Generated by the shell command
        $ makeRandomNFA.pl 2345 64 26 0.03 0.05 0.01 > test-e-NFA5.txt
    (Run makeRandomNFA.pl with no arguments to get usage info.)

test-e-NFA6.txt - A trival 1-state 1-letter NFA meant to test extreme input.
    Hand-edited.  (Same as testNFA4.txt in the simulate directory.)
