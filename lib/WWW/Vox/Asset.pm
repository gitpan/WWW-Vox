# $Id: Asset.pm 1418 2007-08-08 17:21:41Z mpaschal $

package WWW::Vox::Asset;
use warnings;
use strict;

use Carp;

use WWW::Vox::Error;


sub new_from {
    my $class = shift;
    my ($client, $data) = @_;

    my $self = {
        client => $client,
        data   => $data,
    };

    return bless $self, $class;
}

sub asset_id {
    my $asset = shift;
    return $asset->{data}->{id};
}

sub update {
    my $asset = shift;

    my %asset_data = %{ $asset->{data} };
    my $asset_id = delete $asset_data{id};

    ## Remove some fields we can't actually send in the asset data.
    delete @asset_data{qw( thumb_name has_thumbnail thumb_uri uri )};
    delete $asset_data{meta_values};

    my $result = $asset->{client}->request(
        'Library.Asset.Update',
        {
            asset_id => $asset_id,
            asset    => \%asset_data,
        },
    );

    return 1;
}

our $AUTOLOAD;
sub AUTOLOAD {
    my $self = shift;
    (my $field = $AUTOLOAD) =~ s{ \A .* : ([^:]+) \z }{$1}xms;

    ## Find some field named that in our data.
    my $data = $self->{data};
    my $ret = exists $data->{$field}               ? $data->{$field}
            : exists $data->{basic}->{$field}      ? $data->{basic}->{$field}
            : exists $data->{attributes}->{$field} ? $data->{attributes}->{$field}
            : exists $data->{privacy}->{$field}    ? $data->{privacy}->{$field}
            :                                        return
            ;
    return $ret;
}


1;

__END__

=head1 NAME

WWW::Vox::Asset - someone's content element in the Vox system

=head1 SYNOPSIS

    use WWW::Vox;

    my $asset = $search_result->create_asset();
    $asset->{data}->{rating} = 5;
    $asset->update();

=head1 DESCRIPTION

WWW::Vox::Asset represents content assets in the Vox system, providing methods
for altering them. Asset objects are created through WWW::Vox client instances'
C<search()> and C<list_asset()> methods.

=head1 INTERFACE 

=head2 WWW::Vox::Asset->new_from($client, \%data)

Creates a new instance with the given WWW::Vox client and a set of asset data.

=head2 $asset->update()

Saves changes to the asset to the Vox service.

=head1 DIAGNOSTICS

No errors are generated directly in WWW::Vox::Asset.

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
