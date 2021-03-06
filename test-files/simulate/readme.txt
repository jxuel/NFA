This directory contains test files for the NFA simulation portion of
the CSCE 355 programming project.  Below is a list of the files in
this directory with a description of each, including how it was
generated.

Files of the form testNFA#-output.txt (where # is a hex digit) are
    the outputs generated by the solution executable on the
    corresponding inputs, i.e., by the shell command
        $ simulate testNFA#.txt < testNFA#-strings.txt > testNFA#-output.txt

There are two executables available: simulate-linux, which runs on
a Linux machine, and simulate-mac, which runs on an Apple Mac.

---------------

testNFA1.txt - The NFA resulting from removing e-transitions from
    test-e-NFA1.txt (in the e-remove directory).  This NFA is depicted
    in the handout.
    Copied from test-e-NFA1-output.txt in the e-remove directory.

testNFA1-strings.txt - Input strings for testNFA1.txt to simulate.
    Hand-edited.

testNFA2.txt - This is a particular 4-state, 2-letter NFA which exhibits
    "worst-case" behavior of the NFA->DFA subset construction, that
    is, all 2^4 = 16 sets of states are reachable from the start state
    and are distinguishable from each other, making the minimum
    equivalent DFA have 16 states.
    Generated by the shell command
        $ makeWorstCaseNFA.pl 4 > testNFA2.txt
    (Run makeWorstCaseNFA.pl with no arguments to see usage info.)

testNFA2-strings.txt - Input strings for testNFA2.txt to simulate.
    Generated by the shell command
        $ makeWCNFAStrings.pl 4 > testNFA2-strings.txt
    (Run makeWCNFAStrings.pl with no arguments to get usage info.
     Warning: output size grows exponentially in the number of states.)

testNFA3.txt - Same as testNFA2.txt, but this time with 10 states.
    (The minimum equivalent DFA has 2^{10} = 1024 states.)
    Generated by the shell command
        $ makeWorstCaseNFA.pl 10 > testNFA3.txt

testNFA3-strings.txt - Input strings for testNFA3.txt to simulate.
    Generated by the shell command
        $ makeWCNFAStrings.pl 10 > testNFA3-strings.txt
    (Run makeWCNFAStrings.pl with no arguments to get usage info.
     Warning: output size grows exponentially in the number of states.)

testNFA4.txt - A trivial 1-state, 1-letter NFA meant to test extreme input.
    Hand-edited.  (Same as test-e-NFA6.txt in the e-remove directory.)

testNFA4-strings.txt - Input strings for testNFA4.txt to simulate.
    Hand-edited.

testNFA5.txt - Another 1-state NFA, this time with the full 26-letter
    alphabet.
    Hand-edited.

testNFA5-strings.txt - Input strings for testNFA5.txt to simulate.
    Hand-edited.

testNFA6.txt - A randomly generated NFA with 20 states and a 5-letter
    alphabet.
    Generated by the shell command
        $ makeRandomNFA.pl 1234 20 5 0.1 0.0 0.05 > testNFA6.txt
    (Run makeRandomNFA.pl with no arguments to see usage info.)

testNFA6-strings.txt - Randomly generated input strings for
    testNFA6.txt to simulate.
    Generated by the shell command
        $ makeRandomStrings.pl 4321 50 5 20 > testNFA6-strings.txt

testNFA7.txt - Like testNFA6.txt but with different parameters (64
    states and 26 letters).
    Generated by the shell command
        $ makeRandomNFA.pl 2345 64 26 0.03 0.0 0.01 > testNFA7.txt

testNFA7-strings.txt - Randomly generated input strings for
    testNFA7.txt to simulate.
    Generated by the shell command
        $ makeRandomStrings.pl 4321 50 26 20 > testNFA7-strings.txt

testNFA8.txt - A randomly generated, 10-state NFA.
    Copied from test-e-NFA4-output.txt in the e-remove directory.

testNFA8-strings.txt - Randomly generated input strings for
    testNFA8.txt to simulate.
    Generated by the shell command
        $ makeRandomStrings.pl 5432 50 2 20 > testNFA8-strings.txt

testNFA9.txt - A 7-state NFA for finding the substring "abaabc" in the
    input.
    Generated by the shell command
        $ makeTextSearchNFA.pl 3 abaabc
    (Run makeTextSearchNFA.pl with no arguments to get usage info.)

testNFA9-strings.txt - Input strings for testNFA9.txt to simulate.
    Hand-edited.

testNFAa.txt - A 16-state NFA for finding the substring
    "czechiaslovakia" in the input.
    Generated by the shell command
        $ makeTextSearchNFA.pl 26 czechiaslovakia
    (Run makeTextSearchNFA.pl with no arguments to get usage info.)

testNFAa-strings.txt - Input strings for testNFAa.txt to simulate.
    Hand-edited.

testNFAb.txt - A 64-state NFA for finding the substring "zyzxzyzwzyzxzyz
    vzyzxzyzwzyzxzyzuzyzxzyzwzyzxzyzvzyzxzyzwzyzxzyz" in the input.
    Generated by the shell command
        $ makeTextSearchNFA.pl 26 zyzxzyzwzyzxzyzvzyzxzyzwzyzxzyzuzyzxzyzwzyzxzyzvzyzxzyzwzyzxzyz > testNFAb.txt
    (The search string is a 63-letter Zimin word.)

testNFAb-strings.txt - Input strings for testNFAb.txt to simulate.
    Hand-edited.
