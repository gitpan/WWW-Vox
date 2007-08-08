package WWW::Vox::SearchResult;

use warnings;
use strict;
use Carp;

use WWW::Vox::Error;


sub new_from {
    my $class = shift;
    my ($client, $result_hash, $conduit) = @_;

    my $self = {
        client  => $client,
        conduit => $conduit,
        result  => $result_hash,
    };

    return bless $self, $class;
}

sub create_asset {
    my $self = shift;

    my $result = $self->{client}->request(
        'Library.Asset.CreateFromConduit',
        {
            conduit => $self->{conduit},
            id      => $self->{result}->{id},
            asset   => {
                visibility_ugroup_id => 1,
            },
        },
    );

    my $asset_id = $result->{asset_id};
    my $asset    = $self->{client}->retrieve_asset($asset_id);

    return $asset;
}

our $AUTOLOAD;
sub AUTOLOAD {
    my $self = shift;
    (my $field = $AUTOLOAD) =~ s{ \A .* : ([^:]+) \z }{$1}xms;

    ## Find some field in result like that.
    my $result = $self->{result};
    my $ret = exists $result->{$field}               ? $result->{$field}
            : exists $result->{basic}->{$field}      ? $result->{basic}->{$field}
            : exists $result->{attributes}->{$field} ? $result->{attributes}->{$field}
            :                                          return
            ;
    return $ret;
}

1;

__END__

=head1 NAME

WWW::Vox::SearchResult - results of asset searches on the Vox service

=head1 SYNOPSIS

    use WWW::Vox;

    my $vox = WWW::Vox->new( auth => ... );
    my ($result) = $vox->search(
        type    => 'Movie',
        conduit => 'Amazon',
        query   => 'Metropolis',
    );
    my $asset = $result->create_asset();

=head1 DESCRIPTION

WWW::Vox::SearchResult represents a result from a search on the Vox service.
Searches are performed for particular asset I<types>, through I<conduits>.
Searches are performed directly through WWW::Vox client instances using the
C<search> method.

=head1 INTERFACE 

=head2 WWW::Vox::SearchResult->new_from($client, \%result)

Creates a new instance from a WWW::Vox client and a set of search result data.
For internal use.

=head2 $searchresult->create_asset()

Saves this search result as a new asset. Returns the analogous WWW::Vox::Asset
object.

=head1 DIAGNOSTICS

No error messages are generated directly in WWW::Vox::SearchResult.

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
