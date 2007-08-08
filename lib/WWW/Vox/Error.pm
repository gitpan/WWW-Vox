# $Id: Error.pm 1387 2007-08-02 00:32:03Z mpaschal $

package WWW::Vox::Error;
use warnings;
use strict;

use overload '""' => 'as_string';


sub new {
    my ($class, $err, %param) = @_;
    bless { msg => $err, %param }, $class;
}

sub as_string {
    my $self = shift;
    return ($self->{msg} . "\n") || "Died\n";
}


1;

__END__

=head1 NAME

WWW::Vox::Error - An exception object for WWW::Vox errors

=head1 SYNOPSIS

    use WWW::Vox::Error;
    
    die WWW::Vox::Error->new("Oops!", my_bad => 1);

=head1 DESCRIPTION

WWW::Vox::Error is an exception class for errors thrown by WWW::Vox. Extra data
associated with different errors can be saved in an Error's hash members.

=head1 INTERFACE 

=head2 WWW::Vox::Error->new($message, %params)

Creates a new WWW::Vox::Error with the given message and extra parameters
(optional). Extra parameters are accessible through regular hash access methods
(for example, C<< $error->{key} >>).

=head2 "$error"

Returns the WWW::Vox::Error's message.

=head1 DIAGNOSTICS

See individual WWW::Vox modules' definitions for the meaning of various
WWW::Vox::Errors.

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests to C<bug-www-vox@rt.cpan.org>, or
through the web interface at L<http://rt.cpan.org>.

=head1 AUTHOR

Mark Paschal  C<< <mark@sixapart.com> >>

=head1 LICENCE AND COPYRIGHT

Copyright 2006 Six Apart, Ltd. C<< <cpan@sixapart.com> >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.

=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.
