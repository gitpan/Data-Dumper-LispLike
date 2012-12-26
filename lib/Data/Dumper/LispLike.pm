use strict;
use warnings;

package Data::Dumper::LispLike;
# ABSTRACT: Dump perl data structures formatted as Lisp-like S-expressions

use Exporter ();
our @ISA = qw(Exporter);
our @EXPORT = qw(&dumplisp);

sub dumplisp_scalar($) {
	1 == @_ or die;
	my $scalar = shift;
	die unless defined($scalar) and not ref($scalar);
	return( $scalar =~ /^[\w\-%:,\!=]+$/ ? $scalar : "'$scalar'" );
}

sub dumplisp_iter($;$$);
sub dumplisp_iter($;$$) {
	1 == @_ or 2 == @_ or 3 == @_ or die;
	my ($lisp, $level, $maxlength) = @_;
	$level ||= 0;
	$maxlength = 60 unless defined $maxlength;
	my $simple = ( $level < 0 );
	my $indent = "    ";
	if( not defined $lisp ) {
		die;
	} elsif( not ref $lisp ) {
		my $out = $simple ? "" : "\n" . ( $indent x $level );
		$out .= dumplisp_scalar $lisp;
		die if length $out > $maxlength;
		return $out;
	} elsif( 'ARRAY' eq ref $lisp ) {
		my $out = $simple ? "" : "\n" . ( $indent x $level );
		die if $simple and length $out > $maxlength;
		my @l = @$lisp;
		my $first = 1;
		if( not @l ) {
			$out .= "(";
		} elsif( $simple ) {
			$out .= "(";
			foreach my $current ( @l ) {
				$out .= " " unless $first;
				undef $first;
				$out .= dumplisp_iter( $current, -1, $maxlength - length $out );
				die if $simple and length $out > $maxlength;
			}
		} else { # not $simple and @l not empty
			my $try_add = eval {
				dumplisp_iter( $lisp, -1, $maxlength - length $out );
			};
			if( defined $try_add ) {
				my $try_out = $out . $try_add;
				return $try_out if length $try_out <= $maxlength;
			}
			$out .= "(" . dumplisp_scalar shift @l;
			$out .= dumplisp_iter( $_, $level + 1 ) foreach @l;
		}
		$out .= ")";
		die if $simple and length $out > $maxlength;
		return $out;
	} else {
		die;
	}
}


sub dumplisp($) {
	1 == @_ or die "Usage: dumplisp(<expression>)\n";
	my $out = dumplisp_iter shift;
	chomp $out;
	$out =~ s/^\n//;
	return "$out\n";
}

1;


__END__
=pod

=head1 NAME

Data::Dumper::LispLike - Dump perl data structures formatted as Lisp-like S-expressions

=head1 VERSION

version 0.002

=head1 SYNOPSIS

    use Data::Dumper::LispLike;
    print dumplisp [ 1, 2, [3, 4] ]; # prints "(1 2 (3 4))\n";

=head1 FUNCTIONS

=head2 dumplisp

    my $listref = ...;
    print dumplisp $listref;

This function converts an C<ARRAYREF>, which may contain strings or other
C<ARRAYREF>s, into Lisp-like S-expressions. The output is much compacter
and easier to read than the output of C<Data::Dumper>.

=for Pod::Coverage method_names_here

=head1 EXAMPLE

Here is a bigger real-life example of dumplisp() output:

    (COMMA
        (AND
            (CMDDEF
                echo
                (%str)
                (BLOCK (CMDRUN printf '%str\n')))
            (CMDDEF
                echo1
                (%STR)
                (BLOCK (CMDRUN print1 '%STR\n')))
            (CMDDEF kill () (BLOCK (CMDRUN signal KILL)))
            (CMDDEF term () (BLOCK (CMDRUN signal TERM)))
            (CMDDEF hup () (BLOCK (CMDRUN signal HUP)))
            (CMDDEF ps () (BLOCK (CMDRUN exec ps uf '{}')))
            (CMDDEF
                pso
                (%PS_FIELDS)
                (BLOCK (CMDRUN exec ps '-o\-' %PS_FIELDS '{}')))
            (CMDDEF
                exe
                (%exe_arg)
                (BLOCK (COMPARE == %exe %exe_arg)))
            (CMDDEF
                cwd
                (%cwd_arg)
                (BLOCK (COMPARE == %cwd %cwd_arg)))
            (ASSIGN %vsz %statm::size)
            (ASSIGN %rss %statm::resident)
            (CMDDEF kthread () (BLOCK (COMPARE == 0 %rss)))
            (CMDDEF
                userspace
                ()
                (BLOCK (NOT (CMDRUN kthread))))
            (ASSIGN %ppid %stat::ppid)
            (ASSIGN %comm %stat::comm)
            (ASSIGN %state %stat::state))
        (AND
            (BLOCK (OR (CMDRUN userspace) (COMPARE == %pid 2)))
            (BLOCK
                    (OR (CMDRUN userspace) (COMPARE == %pid 23)))
            (CMDRUN ps)))

=head1 SUPPORT

L<http://github.com/spiculator/data-dumper-lisplike>

=head1 AUTHOR

Sergey Redin <sergey@redin.info>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Sergey Redin.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

