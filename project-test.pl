#!/usr/bin/perl -w

# Perl script for testing a CSCE 355 project submission on a linux box

# Usage:
# $ project-test.pl [your-submission-root-directory]
#
# The directory argument is optional.  If not there, then the default is
# $default_submission_root, defined below

# Appends to file "comments.txt" in your submission root directory

# This script must be run under the bash shell!


######## Edit the following to reflect your directory (mandatory):

# root directory for the test files
$test_files_root = "$ENV{HOME}/Desktop/csce355/test-files";

######## Editing below this line is strictly optional. ########

# e-NFAs to feed to the e-transition remover
# (in $test_files_root/e-remove; base names only)
#@e_rem_test_files = ("bigDFA", "biggerDFA", "handoutDFA", "randomDFA1",
#            "randomDFA2", "randomDFA3", "randomDFA4", "randomDFA5");

# NFAs to feed to the simulator
# (in $test_files_root/simulate; base names only)
#@sim_test_files = ("bigDFA", "biggerDFA", "handoutDFA", "randomDFA1",
#        "randomDFA2", "randomDFA3", "randomDFA4", "randomDFA5");


# NOTE: test file names are uniform,
# differing only by number.  If adding or removing test files from these
# directories, you should adhere to the naming convention you see there, and
# the numbers should be contiguous from 1 to n, where n is number of test
# files in the directory.

# This is the subdirectory (relative to your project directory) where the
# script temporarily stores the results of running your code.  Change this
# if you want them placed somewhere else.
$test_outputs = "test-outputs";

# Flag to control deletion of temporary files --
# a nonzero value means all temp files are deleted after they are used;
# a zero value means no temp files will be deleted (but they will be
# overwritten on subsequent executions of this script).
# This flag has NO effect on files created by running your program if
# it times out (that is, exceeds the $timeout limit, below); those files will
# always be deleted.
# Set this value to 0 if you want to examine your own programs' outputs as
# produced by this script.
$delete_temps = 1;

# Time limit for each run of your program (in seconds).  This is the value
# I will use when grading.
$timeout = 11;


############# You should not need to edit below this line. ##############

# Test filenames for the simulator
@sim_test_files = ();

@programs = ("e-remove", "simulate");

# Holds which programs were implemented and what progress was made on each:
# Values:
#    0 - not implemented at all ($prog.txt file does not exist)
#    1 - $prog.txt file exists, but there was an error parsing it
#    2 - $prog.txt parsed OK, but the build failed (error return value)
#    3 - $prog built OK, but execution timed out at least once
#    4 - $prog execution always completed (but there were errors)
#    5 - $prog execution always completed without errors
%progress = ();

# Hash for counting errors for each program (only execution errors counted)
%error_counts = ();

# Holds build and run commands for the program
%build_run = ();

# Check existence and readability of the test files directory
die "Test files directory $test_files_root\n  does not exist or is inaccessible\n"
    unless -d $test_files_root && -r $test_files_root;

#sub main
{
    if (@ARGV) {
    $udir = shift @ARGV;
    $udir =~ s/\/$//;
    $udir ne "" or die "Cannot use root directory\n";
    }
    else {
    print STDERR "Usage: project-test.pl your_source_code_directory\n";
    exit(1);
    }
    $uname = "self-test";
    process_user();
}


sub process_user {
    print "Processing user $uname\n";

    die "No accessible directory $udir ($!)\n"
    unless -d $udir && -r $udir && -w $udir && -x $udir;

    die "Cannot change to directory $udir ($!)\n"
    unless chdir $udir;

    print "Current working directory is $udir\n";

    # Copy STDOUT and STDERR to errlog.txt in $udir
    open STDOUT, "| tee errlog.txt" or die "Can't redirect stdout\n";
    open STDERR, ">&STDOUT" or die "Can't dup stdout\n";
    select STDERR; $| = 1;  # make unbuffered
    select STDOUT; $| = 1;  # make unbuffered

    if (-e "comments.txt") {
    print "comments.txt exists -- making backup comments.bak\n";
    rename "comments.txt", "comments.bak";
    }

    open(COMMENTS, "> comments.txt");

    cmt("Comments for $uname -------- " . now() . "\n");

    mkdir $test_outputs
    unless -d $test_outputs;

    $error_count = 0;

    foreach $prog (@programs) {
    $progress{$prog} = 0;
    $error_counts{$prog} = 0;
    next unless -e "$prog.txt"; # proceed only if implemented
    $progress{$prog}++;
    cmt("parsing $prog.txt ...");
    if (parse_build_run("$prog.txt")) {
        cmt("ERROR PARSING $prog.txt ... SKIPPING $prog\n");
        next;
    }
    cmt(" done\n");
    $progress{$prog}++;
    cmt("building $prog ...\n");
    $rc = 0;
    foreach $command (@{$build_run{BUILD}}) {
        cmt("  $command\n");
        $rc = system($command);
        if ($rc >> 8) {
        cmt("    FAILED ... SKIPPING $prog\n");
        last;
        }
        else {
        cmt("    succeeded\n");
        }
    }
    next if $rc >> 8;
    cmt("done\n");
    $progress{$prog}++;
    $command = $build_run{RUN};
    test_dispatch($prog, $command);
    }

    report_summary();

    rmdir $test_outputs if $delete_temps;

    close COMMENTS;

    print "\nDone.\nComments are in $udir/comments.txt\n\n";
}


sub test_dispatch {
    my ($prog, $command) = @_;

    $out_dir = "$test_outputs/$prog";
    mkdir $out_dir
    unless -d $out_dir;
    $test_dir = "$test_files_root/$prog";
    cmt("testing $prog ...\n");
    $no_error = $no_timeout = 1;
    if ($prog eq "simulate") {
    test_simulate($command);
    $error_count += $error_counts{$prog};
    $no_error = 0 if $error_counts{$prog} > 0;
    }
    elsif ($prog eq "e-remove") {
    test_e_remove($command);
    $error_count += $error_counts{$prog};
    $no_error = 0 if $error_counts{$prog} > 0;
    }
    $progress{$prog} += $no_timeout + $no_error;
    rmdir $out_dir if $delete_temps;
    cmt("done with $prog\n\n");
}


# Sets build_run hash to the building and execution commands for this program
# Returns nonzero if error
sub parse_build_run {
    my ($br_file) = @_;
    open BR, "< $br_file"
    or die "Cannot open $br_file for reading ($!)\n";
    get_line(1) or return 1;
    $line = eat_comments();
    if ($line !~ /^\s*Build:\s*$/i) {
    cmt("NO Build SECTION FOUND; ABORTING PARSE\n");
    return 1;
    }
    $build_run{BUILD} = [];
    get_line(1) or return 1;
    $line = eat_comments();
    $build_run{BUILD} = [];
    while ($line ne "" && $line !~ /^\s*Run:\s*$/i) {
    $line =~ s/^\s*//;
    push @{$build_run{BUILD}}, $line;
    get_line(1) or return 1;
    $line = eat_comments();
    }
    if ($line eq "") {
    cmt("NO Run SECTION FOUND; ABORTING PARSE\n");
    return 1;
    }
    # This is now true: $line =~ /^\s*Run:\s*$/i
    get_line(1) or return 1;
    $line = eat_comments();
    $line =~ s/^\s*//;
    $build_run{RUN} = $line;
    get_line(0) or return 0;
    $line = eat_comments();
    if ($line ne "") {
    cmt("EXTRA TEXT IN FILE; ABORTING PARSE\n");
    return 1;
    }
    close BR;
    return 0;
}


sub get_line {
    my ($flag) = @_;
    return 1
    if defined($line = <BR>);
    if ($flag) {
    cmt(" FILE ENDED PREMATURELY\n");
    }
    return 0;
}


# Swallow comments and blank lines
sub eat_comments {
    chomp $line;
    while ($line =~ /^\s*#/ || $line =~ /^\s*$/) {
    $line = <BR>;
    defined($line) or return "";
    chomp $line;
    }
    return $line
}


sub test_simulate {
    ($command) = @_;

    get_sim_test_files();

    foreach $base (@sim_test_files) {

    cmt("  Running simulate on $test_dir/$base.txt ...\n");

    cmt("    $command $test_dir/$base.txt < $test_dir/${base}-strings.txt > $out_dir/${base}-out.txt 2> $out_dir/${base}-err.txt\n");
    eval {
        local $SIG{ALRM} = sub { die "TIMED OUT\n" };
        alarm $timeout;
        $rc = system("$command $test_dir/$base.txt < $test_dir/${base}-strings.txt > $out_dir/${base}-out.txt 2> $out_dir/${base}-err.txt");
        alarm 0;
    };
    if ($@ && $@ eq "TIMED OUT\n") {
        cmt("    $@");      # program timed out before finishing
        $error_counts{$prog}++;
        unlink "$out_dir/${base}-out.txt"
        if -e "$out_dir/${base}-out.txt";
        unlink "$out_dir/${base}-err.txt"
        if -e "$out_dir/${base}-err.txt";
        $no_timeout = 0;
        next;
    }
    if ($rc >> 8) {
        cmt("    terminated abnormally\n");
        # $error_counts{$prog}++;
        error_report("$out_dir/$base");
    }
    else {
        cmt("    terminated normally\n");
        error_report("$out_dir/$base");
    }

    if (!(-e "$out_dir/${base}-out.txt")) {
        cmt("  OUTPUT FILE $out_dir/${base}-out.txt DOES NOT EXIST\n");
        $error_counts{$prog}++;
        next;
    }

    cmt("  $out_dir/${base}-out.txt exists -- comparing acc/rej outcomes with solution file\n");

    $report = check_sim_outcomes($base);
    unlink "$out_dir/${base}-out.txt" if $delete_temps;
    chomp $report;
    if ($report eq '') {
        cmt("  outcomes match (correct)\n");
    }
    else {
        cmt("  OUTCOMES DIFFER:\nvvvvv\n$report\n^^^^^\n");
        $error_counts{$prog}++;
    }
    }
}


# Get array of test filenames (bases, actually) for the simulate program
sub get_sim_test_files {
    @sim_test_files = ();
    for ($i=1; $i<16; $i++) {
    if ($i >= 10) {   # Get the hex digit
        $tag = chr(ord('a')+$i-10);
    }
    else {
        $tag = $i;
    }
    if (-e "$test_dir/testNFA$tag.txt") {
        push @sim_test_files, "testNFA$tag";
    }
    }
}


sub check_sim_outcomes {
    my ($base) = @_;
    my $report = '';

    my $solSeq = get_outcome_sequence("$test_dir/${base}-output.txt");
    my $testSeq = get_outcome_sequence("$out_dir/${base}-out.txt");

    if ($solSeq ne $testSeq) {
    $report .= "    outcomes differ:\n      $solSeq (solution)\n      $testSeq (yours)\n";
    $error_counts{$prog}++;
    }
    return $report;
}


sub test_e_remove {
    ($command) = @_;

    for ($i=1; -e "$test_dir/test-e-NFA$i.txt"; $i++) {
    $in_base = "$test_dir/test-e-NFA$i";
    $out_base = "$out_dir/testNFA${i}";
    $sol_file = "$test_dir/test-e-NFA$i-output.txt";
    cmt("  Running e-remove on $in_base.txt ...\n");

    cmt("    $command $in_base.txt > ${out_base}-out.txt 2> ${out_base}-err.txt\n");
    eval {
        local $SIG{ALRM} = sub { die "TIMED OUT\n" };
        alarm $timeout;
        $rc = system("$command $in_base.txt > ${out_base}-out.txt 2> ${out_base}-err.txt");
        alarm 0;
    };
    if ($@ && $@ eq "TIMED OUT\n") {
        cmt("    $@");      # program timed out before finishing
        $error_counts{$prog}++;
        unlink "${out_base}-out.txt"
        if -e "${out_base}-out.txt";
        unlink "${out_base}-err.txt"
        if -e "${out_base}-err.txt";
        $no_timeout = 0;
        next;
    }
    if ($rc >> 8) {
        cmt("    terminated abnormally\n");
        # $error_counts{$prog}++;
        error_report($out_base);
    }
    else {
        cmt("    terminated normally\n");
        error_report($out_base);
    }

    if (!(-e "${out_base}-out.txt")) {
        cmt("  OUTPUT FILE $out_base.txt DOES NOT EXIST\n");
        $error_counts{$prog}++;
        next;
    }

    cmt("  $out_base.txt exists -- comparing with solution NFA\n");

    $NFA = "${out_base}-out.txt";
    open NFA_STREAM, "< $NFA"
        or die "Cannot open file `$NFA' for reading ($!)\n";
    open SOL_STREAM, "< $sol_file"
        or die "Cannot open file `$sol_file' for reading ($!)\n";
    $report = compare_NFAs();
    close NFA_STREAM;
    close SOL_STREAM;
    unlink "$out_base.txt" if $delete_temps;
#   chomp $report;
    if (!$report) {
        cmt("  the NFAs are the same (correct)\n");
    }
    else {
        cmt("  THE DFAs DIFFER (INCORRECT):\nvvvvv\n$report\n^^^^^\n");
        $error_counts{$prog}++;
    }
    }
}


sub compare_NFAs {
    # Check for same number of states
    <SOL_STREAM> =~ /^Number of states: (\d+)$/;
    my $num_states = $1;
    if (<NFA_STREAM> !~ /^Number of states:[ \t]*(\d+)[ \t\r]*$/) {
    cmt("    Line 1 is malformed\n");
    return 1;
    }
    if ($num_states != $1) {
    cmt("    Numbers of states differ ($1 vs $num_states)\n");
    return 1;
    }

    # Check for same alphabet size
    <SOL_STREAM> =~ /^Alphabet size: (\d+)$/;
    my $alpha_size = $1;
    if (<NFA_STREAM> !~ /^Alphabet size:[ \t]*(\d+)[ \t\r]*$/) {
    cmt("    Line 2 is malformed\n");
    return 1;
    }
    if ($alpha_size != $1) {
    cmt("    Alphabet sizes differ ($1 vs $alpha_size)\n");
    return 1;
    }

    # Check for same accepting states
    <SOL_STREAM> =~ /^Accepting states: ?((?:\d+(?: \d+)*)?)$/;
    my @sol_acc_states = split ' ', $1;
    my $sol_acc_string = join ' ', @sol_acc_states;
    if (<NFA_STREAM> !~ /^Accepting states:[ \t]*((?:\d+(?:[ \t]+\d+)*)?)$/) {
    cmt("    Line 3 is malformed\n");
    return 1;
    }
    my @accepting_states = split /[ \t]+/, $1;
    my $accepting_string = join ' ', @accepting_states;
    if ($sol_acc_string ne $accepting_string) {
    cmt("    Accepting state lists differ ($accepting_string vs $sol_acc_string)\n");
    return 1;
    }

    # Compare transition tables
    my $state_count = 0;
    while ($line = <NFA_STREAM>) {
    if ($state_count >= $num_states) {
        cmt("    File has too many transition table entries\n");
        return 1;
    }
    chomp $line;
    $sol_line = <SOL_STREAM>;
    chomp $sol_line;
    $sol_line =~ s/}\s+{/}{/g;   # Remove inter-entry whitespace
    $line =~ s/}\s+{/}{/g;       # Remove inter-entry whitespace
    $line =~ s/^\s+//;           # Remove leading whitespace
    $line =~ s/\s+$//;           # Remove trailing whitespace
    if ($line ne $sol_line) {
        cmt("   Transition table mismatch at state $state_count:\n      `$line'\n        vs\n      `$sol_line'\n");
        return 1;
    }
    $state_count++;
    }
    if ($state_count < $num_states) {
    cmt("    File has too few transition table entries ($state_count)\n");
    return 1;
    }
    return 0;
}


sub error_report {
    my ($base) = @_;
    if (-e "${base}-err.txt") {
    if (-s "${base}-err.txt") {
        cmt("  standard error output:\nvvvvv\n");
        $report = `cat ${base}-err.txt`;
        chomp $report;
        cmt("$report\n^^^^^\n");
    }
    unlink "${base}-err.txt" if $delete_temps;
    }
}


sub report_summary {
    my $report;
    cmt("######################################################\n");
    cmt("Summary for $uname:\n\n");

    foreach $prog (@programs) {
    $report = report_progress($prog);
    cmt("$prog: $report with $error_counts{$prog} execution errors\n");
    }
    cmt("\nThere were a total of $error_count execution errors found.\n");
    cmt("######################################################\n");
}


# Possible progress report values:
#    0 - not implemented at all ($prog.txt file does not exist)
#    1 - $prog.txt file exists, but there was an error parsing it
#    2 - $prog.txt parsed OK, but the build failed (error return value)
#    3 - $prog built OK, but execution timed out at least once
#    4 - $prog execution always completed (but there were errors)
#    5 - $prog execution always completed without errors
sub report_progress {
    my ( $prog ) = @_;
    my $p = $progress{$prog};
    my $ret = "\n  progress level $p";
    return "not implemented -- $prog.txt does not exist" . $ret
    if $p == 0;
    return "$prog.txt exists, but there was an error parsing it" . $ret
    if $p == 1;
    return "$prog.txt parsed OK, but build failed" . $ret
    if $p == 2;
    return "built OK, but execution timed out at least once" . $ret
    if $p == 3;
    return "execution always completed, but there were errors" . $ret
    if $p == 4;
    return "execution always completed without errors" . $ret
    if $p == 5;
    return "??? unknown progress status for $prog" . $ret
}


sub cmt {
    my ($str) = @_;
#  print $str;
    print(COMMENTS $str);
}


sub now {
    my $ret;

    my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime;
    $ret = ('Sun','Mon','Tue','Wed','Thu','Fri','Sat')[$wday];
    $ret .= " ";
    $ret .= ('Jan','Feb','Mar','Apr','May','Jun','Jul',
         'Aug','Sep','Oct','Nov','Dec')[$mon];
    $ret .= " $mday, ";
    $ret .= $year + 1900;
    $ret .= " at ${hour}:${min}:${sec} ";
    if ( $isdst ) {
    $ret .= "EDT";
    } else {
    $ret .= "EST";
    }
    return $ret;    
}


sub get_outcome_sequence {
    my ($file) = @_;
    my $ret = '';
    my $src = `cat $file`;
    while ($src =~ /aCCept|rEJect/i) {
    $ret .= $& eq 'accept' ? 'A' : 'R';
    $src = $';
    }
    return $ret;
}