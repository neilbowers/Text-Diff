#!/usr/bin/perl

use strict;
use warnings;

use Test::More 0.96;

use File::Spec;
use File::Temp qw( tempdir );
use Text::Diff;

my %tests = (
    'both have no newlines' => {
        a => 'this has no newline',
        b => 'this also has no newline',
        Context => <<'EOF',
***************
*** 1 ****
! this has no newline
\ No newline at end of file
--- 1 ----
! this also has no newline
\ No newline at end of file
EOF
        Unified => <<'EOF',
@@ -1 +1 @@
-this has no newline
\ No newline at end of file
+this also has no newline
\ No newline at end of file
EOF
    },
    'one has a newline, the other does not' => {
        a => "this has a newline\n",
        b => 'this has a newline',
        Context => <<'EOF',
***************
*** 1 ****
! this has a newline
--- 1 ----
! this has a newline
\ No newline at end of file
EOF
        Unified => <<'EOF',
@@ -1 +1 @@
-this has a newline
+this has a newline
\ No newline at end of file
EOF
    },
    'both have newline' => {
        a => "this has a newline\n",
        b => "this also has a newline\n",
        Context => <<'EOF',
***************
*** 1 ****
! this has a newline
--- 1 ----
! this also has a newline
EOF
        Unified => <<'EOF',
@@ -1 +1 @@
-this has a newline
+this also has a newline
EOF
    },
    'differing number of trailing newlines' => {
        a => "this has newlines\n",
        b => "this has newlines\n\n",
        Context => <<'EOF',
***************
*** 1 ****
  this has newlines
--- 1,2 ----
  this has newlines
+ 
EOF
        Unified => <<'EOF',
@@ -1 +1,2 @@
 this has newlines
+
EOF
    },
);

for my $name ( sort keys %tests ) {
    subtest(
        $name,
        sub {
            for my $style (qw( Context Unified )) {
                my $test = $tests{$name};

                subtest(
                    $style,
                    sub {
                        is(
                            diff(
                                \$test->{a}, \$test->{b},
                                { STYLE => $style }
                            ),
                            $test->{$style},
                            'string diff'
                        );

                        my $dir = tempdir( CLEANUP => 1 );

                        my $file_a = File::Spec->catfile( $dir, 'a.txt' );
                        my $file_b = File::Spec->catfile( $dir, 'b.txt' );

                        _spew( $test->{a}, $file_a );
                        _spew( $test->{b}, $file_b );

                        is(
                            diff( $file_a, $file_b, { STYLE => $style } ),
                            _file_header( $file_a, $file_b, $style )
                                . $test->{$style},
                            'file diff'
                        );
                    }
                );
            }
        }
    );
}

done_testing();

sub _spew {
    my $content = shift;
    my $file    = shift;

    open my $fh, '>', $file or die $!;
    print {$fh} $content or die $!;
    close $fh or die $!;
}

# We're not testing this header here, so we can just let the appropriate style
# class generate it for us.
sub _file_header {
    my $file_a = shift;
    my $file_b = shift;
    my $style  = shift;

    my $header_sub = ( 'Text::Diff::' . $style )->can('file_header');
    return $header_sub->(
        undef,
        {
            FILENAME_A => $file_a,
            MTIME_A    => ( stat($file_a) )[9],
            FILENAME_B => $file_b,
            MTIME_B    => ( stat($file_b) )[9],
        },
    );
}
