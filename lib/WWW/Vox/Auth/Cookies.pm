# $Id: Cookies.pm 1382 2007-08-02 00:05:10Z mpaschal $

package WWW::Vox::Auth::Cookies;
use strict;
use warnings;

use base qw( WWW::Vox::Auth );

use Carp;

sub new {
    my $class = shift;
    my (%param) = @_;

    my $self = $class->SUPER::new();

    my @fields = qw( cookies );
    @$self{@fields} = delete @param{@fields};

    croak "Unknown parameters specified: " . join q{ }, keys %param
        if %param;

    croak "Parameter cookies is required" if !$self->{cookies};

    return $self;
}

sub prepare_http_request {
    my $auth = shift;
    my ($vox, $ua, $req) = @_;

    $ua->cookie_jar($auth->{cookies});

    return 1;
}

1;

__END__

=head1 NAME

WWW::Vox::Auth::Cookies - Authenticate to Vox through web cookies

=head1 SYNOPSIS

    use WWW::Vox;
    use WWW::Vox::Auth::Cookies;

    my $auth = WWW::Vox::Auth::Cookies->new( cookies => { file => 'vox_cookies.txt' } );
    my $vox = WWW::Vox->new( auth => $auth );

    my $ret = $vox->request(...);

=head1 DESCRIPTION

WWW::Vox::Auth::Cookies provides cookie based authentication to WWW::Vox
clients. This authentication method supports all the features of the
HTTP::Cookies module.

=head1 INTERFACE 

=head2 WWW::Vox->new(%params)

Creates a new WWW::Vox::Auth::Cookies authenticator.

I<%params> can contain:

=over 4

=item * cookies

The HTTP::Cookies instance containing the user's cookies.

You can also directly specify the arguments you would give to
HTTP::Cookies::new(), as you can to the LWP::UserAgent::cookie_jar() method.
This is convenient when the cookies are saved in an HTTP::Cookies cookie jar
file, as you can (almost) specify solely the cookie jar's filename.

=back

=head1 DIAGNOSTICS

No errors are generated directly in WWW::Vox::Auth::Cookies.

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
