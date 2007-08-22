# $Id: Vox.pm 1424 2007-08-22 18:38:51Z mpaschal $

package WWW::Vox;
use strict;
use warnings;

our $VERSION = '1.1';

use Carp;
use Data::Dumper;
use HTTP::Request;
use LWP::UserAgent;
use URI;

use Digest::HMAC_SHA1 qw( hmac_sha1_hex );
use JSON::Any;

use constant HOST => 'http://www.vox.com';

use WWW::Vox::Asset;
use WWW::Vox::Error;
use WWW::Vox::SearchResult;

sub new {
    my $class = shift;
    my (%param) = @_;

    my $self = bless {}, ref $class || $class;

    my @fields = qw( auth host debug );
    @$self{@fields} = delete @param{@fields};

    croak "Unknown parameters specified: " . join q{ }, keys %param
        if %param;

    return $self;
}

sub host {
    my $self = shift;
    return $self->{host} || HOST();
}

sub debug {
    my $self = shift;
    my ($msg) = @_;

    return if !$self->{debug};

    $msg .= "\n" if $msg !~ m{ \n \z }xms;

    if (ref $self->{debug} && ref $self->{debug} eq 'CODE') {
        $self->{debug}->($msg);
    }
    else {
        warn $msg;
    }

    1;
}

sub request {
    my $self = shift;
    my ($method, $params) = @_;

    my $request_obj = {
        id     => q() . int rand 10000,
        method => $method,
        params => [ $params ],
    };

    $self->{auth}->prepare_request_obj($self, $request_obj)
        if $self->{auth};

    my $j = JSON::Any->new;
    my $body = eval { $j->objToJson($request_obj); };
    if($@) {
        die WWW::Vox::Error->new("Error converting data to JSON text: $@\n",
            perl_request => $request_obj);
    }

    my $json_endpoint = join q(/), $self->host, 'services', 'json-rpc';
    my $ua = LWP::UserAgent->new;
    my $req = HTTP::Request->new('POST',
                                 $json_endpoint,
                                 [],
                                 $body);

    $self->{auth}->prepare_http_request($self, $ua, $req)
        if $self->{auth};

    $self->debug("Making request: " . Data::Dumper::Dumper($request_obj));

    my $res = $ua->request($req);
    if(!$res->is_success) {
        die WWW::Vox::Error->new("HTTP error: " . $res->status_line . "\n",
            http_request => $req, http_response => $res);
    }

    my $res_data = $j->jsonToObj($res->content);

    my $error = $res_data->{error};
    if(defined $error && (!ref $error || !$error->isa('JSON::NotString'))) {
        die WWW::Vox::Error->new("Service error: $error", json_request => $request_obj);
    }

    return $res_data->{result};
}

sub search {
    my $self = shift;
    my %params = @_;

    for my $param_name (qw( type conduit query )) {
        die WWW::Vox::Error->new("Parameter '$param_name' is required for searches")
            if !defined $params{$param_name};
    }

    ## Conduit param is actually 'name' in the JSON.
    $params{name} = delete $params{conduit};

    $params{offset} ||= 0;
    $params{count}  ||= 10;

    my $result = $self->request(
        'Discover.Search',
        \%params,
    );

    return map { WWW::Vox::SearchResult->new_from($self, $_, $params{name}) } @{ $result->{results} };
}

sub list_assets {
    my $self = shift;
    my %params = @_;

    for my $param_name (qw( type )) {
        die WWW::Vox::Error->new("Parameter '$param_name' is required to list assets")
            if !defined $params{$param_name};
    }

    my $result = $self->request(
        'Library.Asset.Search',
        {
            filters => [
                {
                    type  => 'type',
                    value => $params{type},
                },
            ],
            result_type => 'idlist',
            offset => $params{offset} || 0,
            count  => $params{count}  || 20,
            sort_by => {
                field => $params{sort_field} || 'issued',
                dir   => $params{sort_dir}   || 'descend',
            },
        },
    );

    my $items = $result->{items};
    if (!ref $items || ref $items ne 'ARRAY') {
        die WWW::Vox::Error->new("Searching for assets did not yield any items",
            json_result => $result);
    }

    return $self->retrieve_assets(map { $_->{id} } @$items);
}

sub retrieve_assets {
    my $self = shift;
    my (@asset_ids) = @_;

    my $result = $self->request(
        'Library.Asset.Retrieve',
        {
            asset_ids => [ @asset_ids ],
        },
    );

    my $items = $result->{items};
    if (!ref $items || ref $items ne 'ARRAY') {
        die WWW::Vox::Error->new("Retrieving assets did not yield any items",
            json_result => $result);
    }

    return map { WWW::Vox::Asset->new_from($self, $_) } @$items;
}

sub retrieve_asset { return shift->retrieve_assets(@_) }

sub create_collection {
    my $self = shift;
    my ($name) = @_;

    my $result = $self->request(
        'Library.Collection.Create',
        {
            name => $name,
        },
    );

    return WWW::Vox::Collection->new_from(
        client => $self,
        data   => $result,
    );
}


1;

__END__

=head1 NAME

WWW::Vox - Interact programmatically with Vox

=head1 SYNOPSIS

    use WWW::Vox;
    use WWW::Vox::Auth::Cookies;

    my $cookie_auth = WWW::Vox::Auth::Cookies->new(
        cookies => { file => 'vox_cookies.txt' },
    );
    my $client = WWW::Vox->new( auth => $cookie_auth );

    my ($tag_result) = $client->request('Tag.Autocomplete', { tag => 'foo' });
    print @$tag_result;

    my ($movie_result) = $client->search(
        type    => 'Video',
        conduit => 'Amazon',
        query   => 'foo',
        locale  => 'en_US',
    );
    my $movie_asset = $movie_result->create_asset();

=head1 DESCRIPTION

WWW::Vox provides a Perl interface to the Vox weblog service. Using instances
of WWW::Vox as a client, one can manipulate assets in one's library.

=head1 INTERFACE 

=head2 WWW::Vox->new(%params)

Creates a new, empty WWW::Vox client.

I<%params> can contain:

=over 4

=item * auth

The WWW::Vox::Auth object to use for authentication. The only provided
authentication method is cookie authentication, provided by the
WWW::Vox::Auth::Cookies module. Authentication modules can modify API requests
at the JSON content and HTTP request levels to provide credentials to Vox; see
L<WWW::Vox::Auth>.

=item * host

The initial portion of the URI for the Vox instance your client will use. By
default, this is set to I<http://www.vox.com>, but you can override it by
setting I<host> appropriately. Note that you must include the I<http://> at the
front, and that you don't need a I</> at the end. This option is provided for
testing.

=back

=head2 $vox->request($method, \%params)

Sends a JSON request for the Vox service to perform the task C<$method> with
parameters C<\%params>. Other WWW::Vox modules and methods provide additional
convenience over composing the JSON request yourself for the common actions
they represent, but if necessary, you can roll your own.

=head2 $vox->search(%params)

Search in a conduit for an asset meeting certain criteria, returning a list of
WWW::Vox::SearchResult objects. Required parameters are:

=over 4

=item * type

The asset type for which to search. The searchable asset types are Photo, Book,
Audio, and Video.

=item * conduit

The name of the conduit to search. The available conduits vary by asset type.
Common conduits are Amazon (Book, Audio, and Video), Flickr (Photo), and
YouTube (Video).

=item * query

The string with which to search. What this means varies by asset type and
conduit. For example, when searching Amazon for a Movie, the query should be
the movie's title.

=back

Optional parameters are:

=over 4

=item * count

The number of search results to return. The default is 10.

=item * offset

The number of search results to skip when retrieving this search's results. For
example, to get the next "page" of results, repeat the search with C<offset>
incremented by the previous search's C<count> parameter. The default is 0.

=back

=head2 $vox->list_assets(%params)

Retrieves a number of assets saved in the authenticated user's library. Assets
are returned as WWW::Vox::Asset instances. Required members of C<%params> are:

=over 4

=item * type

The type of the assets to list. Any Vox asset type is listable, including
Photo, Book, Audio, Video, Link, Post, Comment, and Collection.

=back

Other optional parameters are available to specify which set of assets to list.
Optional members of C<%params> are:

=over 4

=item * count

The number of assets to return. By default, up to 20 assets are returned.

=item * offset

The number of assets to skip before returning assets. Increase this parameter
by a previous call's C<count> parameter to list the next "page" of assets. By
default, no assets are skipped (that is, the first "page" is listed).

=item * sort

The field by which to sort the library when looking for the requested assets.
By default, assets are sorted by C<issued> (the date an asset was added to the
user's library).

=item * sort_dir

The direction in which to sort assets. The value of this parameter should be
either C<ascend> or C<descend> (which means newest first, for date fields). By
default, the sorting direction is C<descend>.

=back

Note the combined defaults mean that, when all the optional fields are omitted,
the 20 assets of the specified type most recently added to the user's library
are returned.

=head2 $vox->retrieve_assets(@asset_ids)

Retrieves the WWW::Vox::Assets with the given asset IDs from the Vox service.
Asset IDs are unique across all users and asset types, so you only need the ID.

=head2 $vox->retrieve_asset($asset_id)

Retrieves the WWW::Vox::Asset with the given asset ID from the Vox service.
Asset IDs are unique across all users and asset types, so you only need the ID.

=head2 $vox->create_collection($name)

Creates a new collection, returning the WWW::Vox::Collection object for it.

=head1 DIAGNOSTICS

WWW::Vox produces errors as WWW::Vox::Error exceptions.

=over

=item Error converting data to JSON text: I<message>

C<request> was not able to convert the C<\%data> argument into a JSON formatted
string. You may have passed in something other than a hash reference, or had an
unserializable object or circular reference inside your data structure. See
L<JSON> for more on what data structures can be converted into JSON text.

The exception's C<perl_request> hash member contains the C<\%data> that caused
an error.

=item HTTP error: I<code> I<description>

C<request> was not able to send your request to Vox properly due to the given
error using the HTTP protocol. You may not be able to currently reach Vox, or
something about your request caused a server error.

The error's C<http_request> and C<http_response> hash members contain the
involved HTTP::Request and HTTP::Response objects respectively.

=item Service error: I<message>

C<request> received an error from the Vox service. Your request may have been
proper JSON and a proper request, but malformed. Check that you included all
the necessary arguments for the method you invoked.

=back

=head1 CONFIGURATION AND ENVIRONMENT

WWW::Vox requires no configuration files or environment variables.

=head1 DEPENDENCIES

WWW::Vox uses the CPAN modules Carp, JSON, and LWP.

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
